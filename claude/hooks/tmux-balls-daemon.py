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

调试：TMUX_BALLS_DEBUG=1 时写日志 /tmp/tmux-balls-daemon-<socket>.log
"""
from __future__ import annotations

import fcntl
import os
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


def poll_states() -> dict[str, list[str]] | None:
    """返回 {window_id: [按 pane 顺序的状态, ...]}，只含跑着 claude 的 pane。
    server 不可达时返回 None。"""
    result = tmux("list-panes", "-a", "-F",
                  "#{window_id}\t#{pane_index}\t#{@claude_state}")
    if result.returncode != 0:
        return None
    windows: dict[str, list[tuple[int, str]]] = {}
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        win, idx, state = parts[0], parts[1], parts[2].strip()
        if state in BALLS:
            windows.setdefault(win, []).append((int(idx), state))
    return {w: [s for _, s in sorted(v)] for w, v in windows.items()}


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
                states = polled
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
