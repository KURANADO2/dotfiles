#!/usr/bin/env bash
# =============================================================================
# claude hooks → tmux pane 边框状态灯
# 与实体 ESP32 红绿灯（traffic_light）互补：实体灯报「有状态变化」，
# 边框灯报「是哪个 pane」——多会话并行时扫一眼边框颜色即可定位
#
# 用法（由 ~/.claude/settings.json 的 hooks 调用，勿手动执行）：
#   tmux-status.sh working|waiting|done|clear
#
# 颜色约定（与用户桌面实体红绿灯 traffic_light 的语义完全一致）：
#   working 绿 #5fff00 = claude 正在干活        （UserPromptSubmit / ElicitationResult）
#   waiting 红 #d70000 = 需要用户确认/回答      （PermissionRequest / Elicitation / StopFailure）
#   done    黄 #ffff00 = 本轮任务执行完成       （Stop）
#   clear   移除覆盖  = 该 pane 没在跑 claude，回落 tmux 默认边框（活动蓝/非活动灰）
#                                                        （SessionStart / SessionEnd）
#
# 注意：
# - 状态只体现在「非活动 pane」的边框上（活动 pane 边框永远是活动蓝，这是
#   tmux 的设计，正好符合「盯别的窗」的使用场景）
# - 任何情况都 exit 0：hook 非零退出会被 claude 当作阻断/反馈信号，绝不能
#   因为点灯失败影响 claude 正常工作
# - .zshrc 的 alias 会去掉 TMUX 变量（真彩色修复），但 TMUX_PANE 保留，
#   这里用 TMUX_PANE 定位、走默认 socket，不依赖 TMUX 变量
# =============================================================================
state="${1:-clear}"
pane="${TMUX_PANE:-}"

# 调试开关：TMUX_STATUS_DEBUG=1 时记录每次触发（日常不产生任何 IO）
if [ -n "$TMUX_STATUS_DEBUG" ]; then
  echo "$(date '+%m-%d %H:%M:%S') state=$state pane=[$pane] TMUX=[${TMUX-unset}]" >> /tmp/tmux-status-debug.log
fi

# 不在 tmux 里（如 Terminal.app 直接跑 claude）：静默跳过
[ -z "$pane" ] && exit 0

# 注意：必须用 set-option -p（pane 级边框样式）。
# 不能用 select-pane -P —— tmux 3.8 里那是设置 pane 内容的前景色（window-style），
# 会把整个窗格文字染色而不是染边框（实测踩坑）
case "$state" in
  working) tmux set-option -p -t "$pane" pane-border-style "fg=#5fff00" >/dev/null 2>&1 ;;
  waiting) tmux set-option -p -t "$pane" pane-border-style "fg=#d70000" >/dev/null 2>&1 ;;
  done)    tmux set-option -p -t "$pane" pane-border-style "fg=#ffff00" >/dev/null 2>&1 ;;
  *)       tmux set-option -up -t "$pane" pane-border-style >/dev/null 2>&1 ;;  # clear：移除覆盖，回落默认（活动蓝/非活动灰）
esac
exit 0
