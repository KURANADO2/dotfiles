#!/usr/bin/env bash
# =============================================================================
# dotfiles 一键部署脚本（幂等，可重复执行）
#
# 用法：
#   ./install.sh            # 自动按操作系统选择链接集合
#                           #   macOS → 全套（含 kitty/cursor/hammerspoon 等）
#                           #   Linux → 远程服务器最小集（tmux/nvim/starship/claude 等）
#   DRY_RUN=1 ./install.sh  # 演练模式：只打印将要执行的动作，不落盘
#
# 行为约定：
#   - 目标已是正确软链 → 跳过
#   - 目标是错误软链   → 直接替换
#   - 目标是真实文件   → 先备份为 <名字>.bak-<时间戳> 再替换，绝不静默覆盖
#   - 依赖仓库路径约定：clone 到 ~/Code/GitHub/dotfiles（claude settings.json
#     里的 hooks/statusline 用 $HOME/Code/GitHub/dotfiles 绝对路径引用）
# =============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
OS="$(uname -s)"

link() { # link <仓库内源> <目标链接路径>
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    echo "跳过（源不存在）: ${src}"
    return
  fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "已就绪: $dst"
    return
  fi
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[演练] 将链接: $dst → $src"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    local bak="$dst.bak-$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    echo "已备份原文件: ${bak}"
  fi
  ln -s "$src" "$dst"
  echo "已链接: $dst → $src"
}

echo "== dotfiles 安装（${OS}，仓库：${REPO}）=="

# ---- 统一入口软链 ----
# ~/.dotfiles 指向仓库在本机的实际位置（仓库可 clone 到任意路径，如本机
# ~/Code/GitHub/dotfiles、远程 ~/github/dotfiles）；settings.json、CLAUDE.md
# 的 import、zshrc 的 tnew/clw 全部经 $HOME/.dotfiles 引用仓库，跨机器通用
link "$REPO"                        "$HOME/.dotfiles"

# ---- 通用集（macOS 与 Linux 远程都链接） ----
link "$REPO/tmux/.tmux.conf"        "$HOME/.tmux.conf"
link "$REPO/vim/.vimrc"             "$HOME/.vimrc"
link "$REPO/nvim"                   "$XDG/nvim"
link "$REPO/starship/starship.toml" "$XDG/starship.toml"
link "$REPO/lazygit"                "$XDG/lazygit"
link "$REPO/yazi"                   "$XDG/yazi"
link "$REPO/p10k/.p10k.zsh"         "$HOME/.p10k.zsh"
link "$REPO/claude/settings.json"   "$HOME/.claude/settings.json"
link "$REPO/claude/CLAUDE.md"       "$HOME/.claude/CLAUDE.md"
link "$REPO/claude/skills"          "$HOME/.claude/skills"

# ---- 待办登记簿目录（仓库外集中存放，每项目一册 <项目名>.md， ----
# ---- 格式与硬规则见 claude/CLAUDE.tmux.md「待办登记簿」一节）    ----
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "[演练] 将创建目录: $HOME/.claude/followups"
else
  mkdir -p "$HOME/.claude/followups"
fi

# ---- macOS 专属 ----
if [ "$OS" = "Darwin" ]; then
  link "$REPO/kitty"                              "$XDG/kitty"
  link "$REPO/zsh/.zshrc"                         "$HOME/.zshrc"
  link "$REPO/hammerspoon"                        "$HOME/.hammerspoon"
  link "$REPO/ideavim/.ideavimrc"                 "$HOME/.ideavimrc"
  link "$REPO/sketchybar"                         "$XDG/sketchybar"
  link "$REPO/neovide"                            "$XDG/neovide"
  link "$REPO/cursor/settings.json"               "$HOME/Library/Application Support/Cursor/User/settings.json"
  link "$REPO/cursor/keybindings.json"            "$HOME/Library/Application Support/Cursor/User/keybindings.json"
  link "$REPO/lazydocker"                         "$HOME/Library/Application Support/jesseduffield/lazydocker"
fi

# ---- Linux 专属 ----
if [ "$OS" = "Linux" ]; then
  link "$REPO/dufs/dufs.service" "$XDG/systemd/user/dufs.service"
fi

echo
# ---- 收尾提醒 ----
if [ ! -f "$HOME/.claude_env" ]; then
  echo "⚠️  缺少 ~/.claude_env（claude 的 token/端点/模型映射，不进仓库）。"
  echo "    请创建该文件（chmod 600），格式见 README「~/.claude_env」一节。"
fi

if [ "$OS" = "Darwin" ]; then
  if command -v tmux >/dev/null; then
    v=$(tmux -V | awk '{print $NF}' | tr -cd '0-9.')
    [ "$(printf '%s\n' "$v" 3.3 | sort -V | head -1)" = "3.3" ] || \
      echo "⚠️  tmux 版本 $v 低于 3.3（allow-passthrough 等特性需要），建议升级"
  else
    echo "⚠️  未检测到 tmux（需要 ≥ 3.3）"
  fi
  echo "ℹ️  macOS 全套完成。kitty 内新窗口会自动进入 tmux（见 zsh/.zshrc 末尾）。"
else
  echo "ℹ️  远程最小集完成（未链接 Mac 专属的 zshrc/kitty/cursor 等）。"
  echo "ℹ️  请把下面几行加进远程的 ~/.zshrc 或 ~/.bashrc（ssh 登录为裸 shell，与本机一致，手动 tnew 进 tmux）："
  echo '    # claude 环境与 tmux 工具'
  echo '    [ -f ~/.claude_env ] && source ~/.claude_env'
  echo "    alias claude='env -u TMUX claude'"
  echo '    unalias tnew 2>/dev/null; tnew() { "$HOME/.dotfiles/tmux/workspace/new.sh" "${1:-main}"; }'
  echo '    export PATH="$HOME/.dotfiles/claude/bin:$PATH"'
  echo "ℹ️  远程机器的工作区定义请放 ~/.dotfiles/tmux/workspace/local/main.conf"
  echo "    （local/ 不进仓库，各机器写自己的目录；没有它 tnew main 建普通空会话）"
  echo "ℹ️  settings.json 里的 traffic_light hooks 已带存在性守卫，远程没有该仓库时静默跳过。"
  # dufs 文件共享服务（~/public，仅 tailnet 可见），细节见 README「dufs 文件共享」一节
  if [ -x "$HOME/.local/bin/dufs" ]; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now dufs 2>/dev/null || true
    loginctl enable-linger "$USER" 2>/dev/null || true
    echo "ℹ️  dufs 已启用：HTML/报告写 ~/public，tailnet 内访问 http://$(tailscale ip -4 2>/dev/null || echo '<tailscale-IP>'):5000"
  else
    echo "⚠️  未检测到 ~/.local/bin/dufs，~/public 文件共享不可用；安装见 README「dufs 文件共享」一节"
  fi
fi
