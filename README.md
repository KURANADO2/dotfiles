# dotfiles

kitty / tmux / zsh / nvim / claude code 等个人配置，macOS 本机与 Linux 远程服务器均可一键部署。

## Install

仓库可 clone 到任意路径（本机 `~/Code/GitHub/dotfiles`，远程 `~/github/dotfiles`），
`install.sh` 会建立统一入口软链 `~/.dotfiles` 指向仓库实际位置，仓库内所有互相引用
（settings.json 的 hooks、CLAUDE.md 的 import、zshrc 的 tnew/clw）都走 `$HOME/.dotfiles`，
因此不同机器路径不同也无需改动任何文件：

```bash
git clone git@github.com:KURANADO2/dotfiles.git ~/Code/GitHub/dotfiles   # 用 ssh 协议
cd ~/Code/GitHub/dotfiles
./install.sh            # DRY_RUN=1 ./install.sh 可先演练
```

`install.sh` 幂等可重复执行：已正确的软链跳过、真实文件先备份（`.bak-<时间戳>`）再替换；
按操作系统自动裁剪链接集合：

- **macOS**：全套（kitty、zsh、cursor、hammerspoon 等）
- **Linux（远程服务器）**：最小集（tmux、nvim、starship、lazygit、yazi、claude settings/CLAUDE.md 等）

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

## tmux 工作区（tnew / workspace conf）

- 不自动进 tmux：kitty 启动、`cmd+n` 新 OS 窗口、远程 ssh 登录都是裸 zsh；干活前手动 `tnew <名字>`（两边行为一致）
- `tnew <名字>`：会话已存在 → attach；不存在 → 按 conf 建好工作区再 attach；无 conf → 普通空会话
- `cmd+d` = detach 当前会话（原生 prefix d）：会话转后台持久运行，窗口回到裸 zsh 提示符
  （attach 不用 exec，窗口不关闭），再次 `tnew <名字>` 接回
- conf 查找顺序：`tmux/workspace/local/<名字>.conf`（**机器私有，不进仓库**，各机器目录不同）
  → `tmux/workspace/<名字>.conf`（仓库通用版，如本机的 `main.conf` 8 窗口布局）
- conf 格式 = tmux 原生命令逐行书写（new-window / split-window / select-layout…）
- `cmd+n` 裸窗口的典型用途：ssh 远程再在远程 `tnew`——本地不在 tmux 里，远程 tmux 就不会嵌套
  （两层 tmux 前缀键相同，外层会截获按键）
- 已知取舍：裸 zsh 窗口里按 Cmd 系快捷键会把 tmux 前缀字节打进 shell（零星垃圾字符，无实害）

## 远程服务器（ssh 复用本机 kitty + tmux 全套操作）

原理：本机 kitty 的快捷键是往终端数据流里写「tmux 前缀字节 + 命令键」（见
`kitty/kitty.conf` 的 send_text 映射），ssh 会原样透传这些字节——因此登录远程后，
**本机全部 Cmd 快捷键直接驱动远程 tmux**；且远程会话不怕断网，重连后 `tnew main`
即恢复现场（远程 ssh 登录为裸 shell，与本机一致手动 tnew，不自动进 tmux）。

```bash
# 1. 远程 clone（GitHub 走 ssh 协议；境内服务器 HTTPS 常不通，ssh/443 均可）
git clone git@github.com:KURANADO2/dotfiles.git ~/github/dotfiles
cd ~/github/dotfiles && ./install.sh        # Linux 自动走最小集，并建 ~/.dotfiles 软链

# 2. 远程已有 ~/.claude/settings.json（带 env 块）的话，先把 env 迁移到 ~/.claude_env 再跑 install：
#    python3 - << 'EOF'
#    import json
#    cfg = json.load(open('/home/<user>/.claude/settings.json'))
#    env = cfg.get('env', {})
#    with open('/home/<user>/.claude_env', 'w') as f:
#        for k, v in env.items(): f.write(f"export {k}='{v}'\n")
#    EOF
#    chmod 600 ~/.claude_env

# 3. 远程 ~/.zshrc 追加（install.sh 结束时也会打印这段）：
#    [ -f ~/.claude_env ] && source ~/.claude_env
#    alias claude='env -u TMUX claude'
#    unalias tnew 2>/dev/null; tnew() { "$HOME/.dotfiles/tmux/workspace/new.sh" "${1:-main}"; }
#    export PATH="$HOME/.dotfiles/claude/bin:$PATH"

# 4. 远程自己的工作区：~/.dotfiles/tmux/workspace/local/main.conf（不进仓库）
```

要求：远程 tmux ≥ 3.3（allow-passthrough 需要，3.5a 实测全兼容）；python3（状态栏彩球，可选）；
jq（claude statusline，可选）。settings.json 里的 traffic_light/osascript hooks 带存在性守卫，
远程没有对应脚本时静默跳过。

## 架构速览（kitty + tmux + claude code）

- kitty 只管 OS 窗口与渲染；tab/分屏/布局/会话持久全部由 tmux 承担
- kitty 快捷键经 `send_text` 注入「C-Space 前缀 + 命令键」，无需手按前缀
  （物理 Ctrl-Space 留给 macOS 切输入法，两条通路互不干扰）
- `tnew <名字>` 手动进入 tmux，`cmd+d` 脱离（会话转后台）；`cmd+n` 裸窗口留给 ssh 等场景
- claude 状态经 hooks 显示为状态栏彩球：🟢 干活中(600ms 闪) / 🔴 等确认(180ms 快闪) /
  🟡 完成或空闲(常亮)，节奏与桌面实体 ESP32 红绿灯（traffic_light）一致；
  F1 广播模式在右下角显示「📢 广播中」常驻指示
- 待办登记簿：跨会话台账 `~/.claude/followups/<项目名>.md`（按 git 主仓库归一，worktree
  不分裂），SessionStart 开门播报本项目未关闭条目，状态栏右下角常显「🔔N」全局计数；
  「建议另起单」必须登记、修复完成必须销单（硬规则见 `claude/CLAUDE.tmux.md`）
- 任务接力：handoff skill 生成四段式交接简报 → 登记簿标 `[handed-off(窗口名)]` →
  `clw <窗口名> --brief-file <简报路径>` 开新 tmux 窗口拉起新 claude 会话直接开工
- 细节见 `claude/README.md` 与 `tmux/.tmux.conf` 内逐项注释（每项标注 tmux 原始命令与默认键）

## Update Lazyvim

```
:Lazy update
```
