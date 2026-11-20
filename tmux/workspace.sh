#!/usr/bin/env bash
# =============================================================================
# tmux 工作区初始化脚本 —— 取代原 kitty/workspace.conf（startup_session）
#
# 用法：直接执行（.zshrc 里冷启动时会自动调用），建好 main 会话并 attach
# 窗口结构 1:1 复刻原 workspace.conf 的 9 个 tab：
#   Note / Tmp / abup_rag(2 pane 网格) / Backend(5 pane 网格) /
#   Frontend(2 pane, stack 即缩放态) / File / Ubuntu / Dify
# =============================================================================
set -e

S=main

# 已存在则直接接回（zshrc 正常不会走到这支，防手动误执行建出重复会话）
if tmux has-session -t "$S" 2>/dev/null; then
  exec tmux attach -t "$S"
fi

tmux new-session  -d -s "$S"      -n Note     -c "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Note"
tmux new-window       -t "$S"     -n Tmp      -c "$HOME/Tmp"

# abup_rag：两个并排 pane（原 layout grid）
tmux new-window       -t "$S"     -n abup_rag -c "$HOME/Code/GitLab/abup-rag"
tmux split-window  -h -t "$S:abup_rag"        -c "$HOME/Code/GitLab/abup-rag"

# Backend：五个 pane 平铺（原 layout grid）
tmux new-window       -t "$S"     -n Backend  -c "$HOME/Code/GitLab/abup-rag"
tmux split-window  -h -t "$S:Backend"         -c "$HOME/Code/GitLab/aidota-skill"
tmux split-window  -h -t "$S:Backend"         -c "$HOME/Code/GitLab/rag-backend"
tmux split-window  -h -t "$S:Backend"         -c "$HOME/Code/GitLab/rag-frontend"
tmux split-window  -h -t "$S:Backend"         -c "$HOME/Code/GitLab/aiab-db-script"
tmux select-layout    -t "$S:Backend" tiled

# Frontend：两个 pane，默认 stack 观感（原 workspace.conf 未写 layout，kitty 默认 stack）
# 用 zoom（resize-pane -Z）模拟：只显示第一个 pane，cmd+shift+= 切换显示另一个
tmux new-window       -t "$S"     -n Frontend -c "$HOME/Code/GitLab/abup-rag/frontend"
tmux split-window  -h -t "$S:Frontend"        -c "$HOME/Code/GitLab/rag-prototype"
tmux resize-pane    -t "$S:Frontend.1" -Z

tmux new-window       -t "$S"     -n File     -c "$HOME/Downloads"
tmux new-window       -t "$S"     -n Ubuntu   -c "$HOME/Downloads"
tmux new-window       -t "$S"     -n Dify     -c "$HOME/Downloads"

tmux select-window    -t "$S:Note"
exec tmux attach      -t "$S"
