#!/usr/bin/env bash
# =============================================================================
# tmux 会话工作区加载器 —— tnew 的实际后端
#
# 用法：new.sh [会话名]        # 缺省 main
#
# 行为（「创建或打开」二合一）：
#   1. 会话已存在 → 直接 attach
#   2. 不存在 → 按 conf 建好整个工作区再 attach，conf 查找顺序：
#        tmux/workspace/local/<名字>.conf   （机器私有，gitignore，各机目录不同）
#        tmux/workspace/<名字>.conf         （仓库通用版）
#   3. 没有对应 conf → 建普通空会话
#
# conf 格式 = tmux 原生命令逐行书写（new-window / split-window / select-layout…），
# 由本脚本在「刚创建的会话是最近使用会话」的上下文中 source-file 执行，
# 因此 conf 内的窗口目标可省略会话名（写 -t :窗口名 即可）
# =============================================================================
set -e

name="${1:-main}"
REPO="$(cd "$(dirname "$0")/../.." && pwd)"

if tmux has-session -t "$name" 2>/dev/null; then
  exec tmux attach -t "$name"
fi

conf="$REPO/tmux/workspace/local/$name.conf"
[ -f "$conf" ] || conf="$REPO/tmux/workspace/$name.conf"

if [ ! -f "$conf" ]; then
  exec tmux new-session -s "$name"
fi

# 先建带占位窗口的会话，再执行 conf 增加窗口，最后杀掉占位窗口；
# 配置里 renumber-windows=on 会把窗口自动重排回 1..N
tmux new-session -d -s "$name" -n "_init"
tmux source-file "$conf"
tmux kill-window -t "$name:_init"
tmux select-window -t "$name:1" 2>/dev/null || true
exec tmux attach -t "$name"
