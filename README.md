# dotfiles

kitty / tmux / zsh / nvim / claude code 等个人配置，macOS 本机与 Linux 远程服务器均可一键部署。

## Install

```bash
git clone git@github.com:KURANADO2/dotfiles.git ~/Code/GitHub/dotfiles
cd ~/Code/GitHub/dotfiles
./install.sh
```

`install.sh` 幂等可重复执行：已正确的软链跳过、真实文件先备份（`.bak-<时间戳>`）再替换；按操作系统自动裁剪链接集合：

- **macOS**：全套（kitty、zsh、cursor、hammerspoon、sketchybar 等）
- **Linux（远程服务器）**：最小集（tmux、nvim、starship、lazygit、yazi、claude settings 等）

### ~/.claude_env（必需，不在仓库内）

claude code 的凭证与模型环境变量存放在仓库外——**本仓库是公开的，token 绝不进库**。
`install.sh` 会把 `claude/settings.json`（消毒版，无 env 块）链接到 `~/.claude/settings.json`，
凭证由 zshrc 自动 source `~/.claude_env` 提供。创建示例：

```bash
cat > ~/.claude_env << 'EOF'
export ANTHROPIC_AUTH_TOKEN='<你的token>'
export ANTHROPIC_BASE_URL='<你的端点>'
export ANTHROPIC_MODEL='<模型名>'
EOF
chmod 600 ~/.claude_env
```

**更新 token 或切换模型**：直接编辑 `~/.claude_env` 里对应的 export 行即可
（模型映射还有 `ANTHROPIC_DEFAULT_OPUS/SONNET/HAIKU/FABLE_MODEL` 等可选变量）。
改完后**新开的终端/新启动的 claude 会话**生效；正在运行的 claude 会话沿用旧值，需重启。

## 远程服务器（ssh 复用本机 kitty + tmux 全套操作）

原理：本机 kitty 的快捷键是往终端数据流里写「tmux 前缀字节 + 命令键」（见
`kitty/kitty.conf` 的 send_text 映射），ssh 会原样透传这些字节——因此登录远程后，
**本机全部 Cmd 快捷键直接驱动远程 tmux**，零额外配置；且远程会话不怕断网，
重连 attach 即恢复现场。

```bash
# 1. 远程 clone 仓库（路径保持一致：settings.json 的 hooks/statusline 以
#    $HOME/Code/GitHub/dotfiles 引用仓库文件）
git clone git@github.com:KURANADO2/dotfiles.git ~/Code/GitHub/dotfiles
cd ~/Code/GitHub/dotfiles && ./install.sh    # Linux 自动走最小集

# 2. 远程 ~/.zshrc 或 ~/.bashrc 追加：ssh 进来自动进入 tmux
[[ $- == *i* && -n "$SSH_TTY" && -z "$TMUX" ]] && exec tmux new -A -s main

# 3.（可选）远程也跑 claude 的话，再追加：
# [ -f ~/.claude_env ] && source ~/.claude_env
# alias claude='env -u TMUX claude'
# export PATH="$HOME/Code/GitHub/dotfiles/claude/bin:$PATH"
```

要求：远程 tmux ≥ 3.3（allow-passthrough 需要）；python3（状态栏彩球守护进程，可选）；
jq（claude statusline，可选）。`tmux/workspace.sh` 是 Mac 本机的 8 窗口工作区，
远程不适用（用 `tmux new -A -s main` 空会话起步即可）。

## 架构速览（kitty + tmux + claude code）

- kitty 只管 OS 窗口与渲染；tab/分屏/布局/会话持久全部由 tmux 承担
- kitty 快捷键经 `send_text` 注入「C-Space 前缀 + 命令键」，无需手按前缀
  （物理 Ctrl-Space 留给 macOS 切输入法，两条通路互不干扰）
- kitty 内 zsh 自动进入 tmux：共享 main 会话；cmd+n 独立 OS 窗口 = 独立会话
- claude 状态经 hooks 显示为状态栏彩球：🟢 干活中(600ms 闪) / 🔴 等确认(180ms 快闪) /
  🟡 完成或空闲(常亮)，节奏与桌面实体 ESP32 红绿灯（traffic_light）一致；
  F1 广播模式在右下角显示「📢 广播中」常驻指示
- 任务接力：`clw <窗口名> "<交接简报>"` 开新 tmux 窗口拉起新 claude 会话
- 细节见 `claude/README.md` 与 `tmux/.tmux.conf` 内逐项注释（每项标注 tmux 原始命令与默认键）

## Update Lazyvim

```
:Lazy update
```
