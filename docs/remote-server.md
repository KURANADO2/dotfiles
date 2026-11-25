# 远程服务器部署（Linux）

目标：ssh 到远程服务器后，复用本机 kitty + tmux 的全套操作与 claude 环境，且断网不丢现场

## 1. 原理

本机 kitty 的快捷键是往终端数据流里写「tmux 前缀字节 + 命令键」（见 `kitty/kitty.conf` 的 `send_text` 映射），ssh 会原样透传这些字节——因此登录远程后，**本机全部 Cmd 快捷键直接驱动远程 tmux**。远程 ssh 登录为裸 shell（与本机一致，不自动进 tmux），手动 `tnew` 进入远程自己的 tmux 会话；会话不怕断网，重连后 `tnew main` 即恢复现场

ssh 前本机不要身处 tmux 内（用 `cmd+n` 新开裸窗口），远程 tmux 就不会嵌套——两层 tmux 前缀键相同，外层会截获按键

## 2. 部署步骤

### 1. clone 并安装

GitHub 走 ssh 协议（境内服务器 HTTPS 常不通，ssh/443 均可）：

```bash
git clone git@github.com:KURANADO2/dotfiles.git ~/github/dotfiles
cd ~/github/dotfiles && ./install.sh        # Linux 自动走最小集，并建 ~/.dotfiles 软链
```

### 2. 迁移旧 settings.json 的 env 块（如有）

远程已有 `~/.claude/settings.json`（带 env 块）的话，先把 env 迁移到 `~/.claude_env` 再跑 install（install 会把旧文件备份为 `.bak-<时间戳>` 再替换）：

```bash
python3 - << 'EOF'
import json
cfg = json.load(open('/home/<user>/.claude/settings.json'))
env = cfg.get('env', {})
with open('/home/<user>/.claude_env', 'w') as f:
    for k, v in env.items(): f.write(f"export {k}='{v}'\n")
EOF
chmod 600 ~/.claude_env
```

全新机器跳过这步，直接按 README「快速开始」创建 `~/.claude_env` 即可

### 3. ~/.zshrc 追加

`install.sh` 结束时也会打印这段：

```bash
[ -f ~/.claude_env ] && source ~/.claude_env
alias claude='env -u TMUX claude'
unalias tnew 2>/dev/null; tnew() { "$HOME/.dotfiles/tmux/workspace/new.sh" "${1:-main}"; }
export PATH="$HOME/.dotfiles/claude/bin:$PATH"
```

各行作用：凭证注入；去掉 TMUX 变量让 claude 保持真彩（TERM 不变，实测验证）；`tnew` 工作区函数；`clw` / `clw-tree` 进 PATH

### 4. 远程自己的工作区

工作区定义放 `~/.dotfiles/tmux/workspace/local/main.conf`（`local/` 不进仓库，各机器写自己的目录，conf 格式 = tmux 原生命令逐行书写）；没有它 `tnew main` 建普通空会话

## 3. 环境要求

| 依赖 | 用途 | 必需 |
|---|---|---|
| tmux ≥ 3.3 | `allow-passthrough` 需要（3.5a 实测全兼容） | 是 |
| python3 | 状态栏彩球守护进程、F2 谱系树 | 可选 |
| jq | claude statusline | 可选 |

settings.json 里的 traffic_light/osascript 等 hooks 带存在性守卫，远程没有对应脚本时静默跳过，无需改配置

## 4. 配套服务

- dufs 文件共享（`~/public`，仅 tailnet 可见）：`install.sh` 自动链接并启用 systemd 用户级服务，二进制需一次性手动安装，见 [docs/dufs.md](dufs.md)
- nvim 插件同步：服务器 pull 仓库后跑 `:Lazy restore` 对齐 lockfile 版本，lockfile 只在 Mac 上 `:Lazy update` 后提交
