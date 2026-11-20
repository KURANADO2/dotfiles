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

# 记录 pane 级状态（守护进程轮询此选项聚合彩球）
case "$state" in
  working|waiting|done)
    tmux set-option -p -t "$pane" @claude_state "$state" >/dev/null 2>&1
    ;;
  *)
    tmux set-option -up -t "$pane" @claude_state >/dev/null 2>&1
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
