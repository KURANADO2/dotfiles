#!/usr/bin/env bash
# =============================================================================
# claude hooks → tmux 状态记录 + 状态栏彩球守护进程踢起
#
# 展示层是 tmux 状态栏的窗口彩球（见 tmux-balls-daemon.py）：
#   working 🟢 闪烁(600ms) = claude 正在干活       （UserPromptSubmit / ElicitationResult）
#   waiting 🔴 快闪(180ms) = 需要用户确认/回答     （PermissionRequest / Elicitation / StopFailure）
#   done    🟡 常亮        = 任务完成或会话空闲     （Stop / SessionStart——对齐实体灯
#                            idle=黄灯常亮的语义：只要 claude 开着就有黄球）
#   clear   移除状态       = 会话结束、不再显示球   （SessionEnd）
# 闪烁节奏与桌面实体 ESP32 红绿灯（traffic_light）固件一致。
#
# hook 是边沿触发，漏事件球会卡在旧状态（如进程被 kill -9 时 SessionEnd 不触发）。
# 兜底：本脚本把 hook stdin JSON 里的 session_id 和时间戳一并写到 pane 选项
# （@claude_session_id / @claude_state_ts），守护进程每 3 秒用
# `claude agents --json`（官方支持的外部状态接口，含 busy/waiting/idle）
# 按 sessionId 对照纠偏，详见 tmux-balls-daemon.py。
#
# 历史注记：曾用 pane 边框颜色做状态灯，但边框色只在非活动 pane 可见，
# 点击 pane 后被活动蓝覆盖，存在设计冲突，2026-11-20 改为状态栏彩球方案
#
# 用法（由 ~/.claude/settings.json 的 hooks 调用，勿手动执行）：
#   tmux-status.sh working|waiting|done|clear
#
# 注意：任何情况都 exit 0——hook 非零退出会被 claude 当作阻断/反馈信号
# =============================================================================
state="${1:-clear}"
pane="${TMUX_PANE:-}"

# 调试开关：TMUX_STATUS_DEBUG=1 时记录每次触发（日常不产生任何 IO）
if [ -n "$TMUX_STATUS_DEBUG" ]; then
  echo "$(date '+%m-%d %H:%M:%S') state=$state pane=[$pane] TMUX=[${TMUX-unset}]" >> /tmp/tmux-status-debug.log
fi

# 不在 tmux 里（如 Terminal.app 直接跑 claude）：静默跳过
[ -z "$pane" ] && exit 0

# 从 hook stdin JSON 提取 session_id（单行 JSON，sed 足够，不依赖 jq；
# 手动执行等无 stdin 场景取到空串，跳过写入即可）
input="$(cat 2>/dev/null)"
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

# 记录 pane 级状态 + 会话绑定 + 写入时间（守护进程轮询聚合彩球、按 ts 判断纠偏时机）
case "$state" in
  working|waiting|done)
    tmux set-option -p -t "$pane" @claude_state "$state" >/dev/null 2>&1
    tmux set-option -p -t "$pane" @claude_state_ts "$(date +%s)" >/dev/null 2>&1
    [ -n "$sid" ] && tmux set-option -p -t "$pane" @claude_session_id "$sid" >/dev/null 2>&1
    ;;
  *)
    tmux set-option -up -t "$pane" @claude_state >/dev/null 2>&1
    tmux set-option -up -t "$pane" @claude_state_ts >/dev/null 2>&1
    tmux set-option -up -t "$pane" @claude_session_id >/dev/null 2>&1
    ;;
esac

# 清理历史版本可能留下的边框覆盖（自愈，幂等）
tmux set-option -up -t "$pane" pane-border-style >/dev/null 2>&1

# 踢起状态栏守护进程（文件锁保证单实例，已在跑则立刻退出；
# 即使本次是 clear 也踢一脚，让它有机会清理残球并自行退出）
DIR="$(cd "$(dirname "$0")" && pwd)"
if command -v python3 >/dev/null 2>&1; then
  nohup python3 "$DIR/tmux-balls-daemon.py" >/dev/null 2>&1 &
fi
exit 0
