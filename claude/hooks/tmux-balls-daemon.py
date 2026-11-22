#!/usr/bin/env python3
"""tmux 状态栏彩球守护进程 —— claude 会话状态的显眼展示层

由 tmux-status.sh（claude hooks）踢起，通常无需手动运行。

工作原理：
  1. 每 180ms 轮询一次全部 pane 的 @claude_state 用户选项（hook 写入）
  2. 每 60ms 按闪烁相位重算每个窗口的彩球串，写入该窗口的 @claude_balls 选项
  3. tmux.conf 的 window-status-format 引用 #{@claude_balls}，状态栏即显示
     例如「6 File 🟢🔴🟡🟢」——每个跑 claude 的 pane 一颗球（按 pane 顺序），
     没跑 claude 的 pane 不占球，整个窗口没有 claude 则不显示球
  4. 闪烁 = 亮球与 ⚫（灯灭）交替，与桌面实体 ESP32 红绿灯固件节奏一致：
     working 绿  600ms 亮 / 600ms 灭（固件 WORKING_BLINK_MS=600）
     waiting 红  180ms 亮 / 180ms 灭（固件 WAITING_BLINK_MS=180）
     done    黄  常亮（固件 idle 黄灯常亮）
     用 ⚫ 而不是删字符，是为了宽度稳定、状态栏不抖动
  5. 没有任何 claude 状态持续 5 秒后自动退出；文件锁保证同一 socket 单实例
  6. 轮询纠偏：hook 是边沿触发，漏一个事件球就卡在旧状态（如 claude 被
     kill -9 时 SessionEnd 不触发）。每 3 秒跑一次 `claude agents --json`
     （官方支持的外部状态接口），按 pane 的 @claude_session_id 对照权威
     status（busy/waiting/idle）纠偏 @claude_state；会话已消失则清球。
     仅纠偏「hook 写入已超过 4 秒」的 pane，避免与刚触发的 hook 抢写

调试：TMUX_BALLS_DEBUG=1 时写日志 /tmp/tmux-balls-daemon-<socket>.log
"""
from __future__ import annotations

import fcntl
import json
import os
import shutil
import subprocess
import sys
import time

# ---- 常量（闪烁节奏与 traffic_light 固件对齐） ----
TICK = 0.06              # 相位计算间隔 60ms（红闪 180ms 半周期的 1/3）
POLL_EVERY = 3           # 每 3 tick（180ms）轮询一次 pane 状态
EXIT_AFTER = 5.0         # 无任何状态持续 N 秒后退出
GREEN_PERIOD_MS = 1200   # 绿：600 亮 + 600 灭
GREEN_ON_MS = 600
RED_PERIOD_MS = 360      # 红：180 亮 + 180 灭
RED_ON_MS = 180

# ---- 轮询纠偏（claude agents --json，实测单次约 130ms） ----
AGENTS_POLL_EVERY = 50   # 每 50 tick（3 秒）跑一次 claude agents --json
AGENTS_TIMEOUT = 2.0     # 子进程超时，超时视为本轮失败
CORRECT_MIN_AGE = 4.0    # hook 写入超过 N 秒才允许纠偏（大于轮询间隔，防抢写）

# claude agents --json 的 status/state → 彩球状态
STATUS_MAP = {"busy": "working", "waiting": "waiting", "idle": "done"}
STATE_MAP = {"working": "working", "blocked": "waiting",
             "done": "done", "failed": "done", "stopped": "done"}

# claude 可执行文件：hook 环境继承自 claude 进程，PATH 里通常有；兜底常见安装位
CLAUDE_BIN = shutil.which("claude") or os.path.expanduser("~/.local/bin/claude")

# 状态 → (亮球, 灭球)
BALLS = {
    "working": ("🟢", "⚫"),
    "waiting": ("🔴", "⚫"),
    "done": ("🟡", "🟡"),  # 常亮：灭相位也是自己
}

# ---- socket 识别：hook 继承的 TMUX 变量指向哪个 server 就服务哪个 ----
# （交互式 claude 经 alias 去掉了 TMUX，此时走默认 socket，即主 server）
_tmux_env = os.environ.get("TMUX", "")
SOCK_ID = os.path.basename(_tmux_env.split(",")[0]) if _tmux_env else "default"
LOCK_PATH = f"/tmp/tmux-balls-daemon-{SOCK_ID}.lock"
LOG_PATH = f"/tmp/tmux-balls-daemon-{SOCK_ID}.log"
DEBUG = bool(os.environ.get("TMUX_BALLS_DEBUG"))


def log(message: str) -> None:
    if not DEBUG:
        return
    try:
        with open(LOG_PATH, "a", encoding="utf-8") as fh:
            fh.write(f"{time.strftime('%H:%M:%S')} {message}\n")
    except OSError:
        pass


def tmux(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["tmux", *args], capture_output=True, text=True)


def poll_states() -> tuple[dict[str, list[str]], list[dict]] | None:
    """返回 ({window_id: [按 pane 顺序的状态, ...]}, [pane 详情, ...])。
    窗口字典只含跑着 claude 的 pane；pane 详情含纠偏所需的
    pane_id / state / session_id / ts。server 不可达时返回 None。"""
    result = tmux("list-panes", "-a", "-F",
                  "#{window_id}\t#{pane_index}\t#{@claude_state}"
                  "\t#{pane_id}\t#{@claude_session_id}\t#{@claude_state_ts}")
    if result.returncode != 0:
        return None
    windows: dict[str, list[tuple[int, str]]] = {}
    panes: list[dict] = []
    for line in result.stdout.splitlines():
        parts = (line.split("\t") + [""] * 6)[:6]
        win, idx, state, pane_id, sid, ts = parts[0], parts[1], parts[2].strip(), parts[3], parts[4].strip(), parts[5].strip()
        if state in BALLS:
            windows.setdefault(win, []).append((int(idx), state))
        if pane_id and (state in BALLS or sid):
            panes.append({"pane_id": pane_id, "state": state,
                          "sid": sid, "ts": ts})
    return {w: [s for _, s in sorted(v)] for w, v in windows.items()}, panes


def fetch_agents() -> dict[str, str] | None:
    """跑 `claude agents --json`，返回 {sessionId: 彩球状态}（仅活会话）。
    任何失败（二进制缺失、超时、非零退出、JSON 异常）返回 None，本轮跳过。"""
    if not os.path.exists(CLAUDE_BIN):
        return None
    try:
        result = subprocess.run([CLAUDE_BIN, "agents", "--json"],
                                capture_output=True, text=True,
                                timeout=AGENTS_TIMEOUT)
        if result.returncode != 0:
            return None
        entries = json.loads(result.stdout)
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return None
    agents: dict[str, str] = {}
    if not isinstance(entries, list):
        return None
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        sid = entry.get("sessionId")
        if not sid:
            continue
        desired = STATUS_MAP.get(entry.get("status", "")) \
            or STATE_MAP.get(entry.get("state", ""))
        if desired:
            agents[sid] = desired
    return agents


def correct_states(panes: list[dict], agents: dict[str, str]) -> None:
    """按 claude agents --json 的权威状态纠偏 pane 选项。
    仅处理绑定了 session_id 且 hook 写入已超过 CORRECT_MIN_AGE 秒的 pane，
    避免与刚触发的 hook 抢写（hook 永远更即时）。"""
    now = time.time()
    for pane in panes:
        sid = pane["sid"]
        if not sid:
            continue
        try:
            age = now - float(pane["ts"]) if pane["ts"] else float("inf")
        except ValueError:
            age = float("inf")
        if age < CORRECT_MIN_AGE:
            continue
        desired = agents.get(sid)
        if desired is None:
            # 会话已不在活会话列表（进程没了，SessionEnd 可能漏触发）：清球
            if pane["state"]:
                log(f"纠偏：会话 {sid[:8]} 已消失，清 pane {pane['pane_id']} 的球")
                tmux("set-option", "-up", "-t", pane["pane_id"], "@claude_state")
                tmux("set-option", "-up", "-t", pane["pane_id"], "@claude_state_ts")
                tmux("set-option", "-up", "-t", pane["pane_id"], "@claude_session_id")
        elif desired != pane["state"]:
            log(f"纠偏：会话 {sid[:8]} pane {pane['pane_id']} "
                f"{pane['state'] or '(无)'} → {desired}")
            tmux("set-option", "-p", "-t", pane["pane_id"], "@claude_state", desired)
            tmux("set-option", "-p", "-t", pane["pane_id"],
                 "@claude_state_ts", str(int(now)))


def render(states: list[str], now_ms: int) -> str:
    green_on = (now_ms % GREEN_PERIOD_MS) < GREEN_ON_MS
    red_on = (now_ms % RED_PERIOD_MS) < RED_ON_MS
    out = []
    for state in states:
        on, off = BALLS[state]
        if state == "working":
            out.append(on if green_on else off)
        elif state == "waiting":
            out.append(on if red_on else off)
        else:
            out.append(on)
    return "".join(out)


def main() -> int:
    # 脱离 hook 的进程组，避免被 hook 超时清理波及
    try:
        os.setsid()
    except OSError:
        pass

    # 单实例锁：已有守护进程在跑就直接退出
    lock = open(LOCK_PATH, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return 0
    lock.write(str(os.getpid()))
    lock.flush()
    log(f"daemon 启动 sock={SOCK_ID} pid={os.getpid()}")

    cache: dict[str, str] = {}   # window_id → 上次写入的彩球串
    states: dict[str, list[str]] = {}
    panes: list[dict] = []
    last_state_seen = time.monotonic()
    poll_failures = 0
    tick = 0

    while True:
        if tick % POLL_EVERY == 0:
            polled = poll_states()
            if polled is None:
                poll_failures += 1
                if poll_failures > 30:   # server 没了（约 2 秒不可达）
                    log("server 不可达，退出")
                    return 0
            else:
                poll_failures = 0
                states, panes = polled
        # 轮询纠偏：3 秒一次，失败静默跳过（hook 链路仍是主通道）
        if panes and tick % AGENTS_POLL_EVERY == 0:
            agents = fetch_agents()
            if agents is not None:
                correct_states(panes, agents)
        tick += 1

        if states:
            last_state_seen = time.monotonic()
        elif time.monotonic() - last_state_seen > EXIT_AFTER:
            log("无状态超时，退出")
            break

        now_ms = int(time.time() * 1000)
        changed = False
        for win, st in states.items():
            balls = render(st, now_ms)
            if cache.get(win) != balls:
                tmux("set-option", "-w", "-t", win, "@claude_balls", balls)
                cache[win] = balls
                changed = True
        for win in list(cache):
            if win not in states and cache[win] != "":
                # 该窗口已无 claude 状态（或窗口已销毁）：移除彩球
                tmux("set-option", "-uw", "-t", win, "@claude_balls")
                cache[win] = ""
                changed = True
        if changed:
            tmux("refresh-client", "-S")

        time.sleep(TICK)

    log("daemon 正常退出")
    return 0


if __name__ == "__main__":
    sys.exit(main())
