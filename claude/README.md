# claude × tmux 协作组件

第二批「tmux + claude code 联动」的落地文件。安装与配置状态见各文件头注释。

| 文件 | 作用 | 生效方式 |
|---|---|---|
| `hooks/tmux-status.sh` | 记录 pane 级 claude 状态（`@claude_state`）并踢起彩球守护进程，claude hooks 调用 | `~/.claude/settings.json` 的 hooks 段（已配置） |
| `hooks/tmux-balls-daemon.py` | 状态栏彩球守护：60ms 相位循环，按 traffic_light 固件节奏（绿 600ms 闪/红 180ms 快闪/黄常亮）把各窗口的彩球串写入 `@claude_balls`；无状态 5 秒自动退出，文件锁单实例 | 由 tmux-status.sh 自动拉起；`window-status-format` 引用（已配置） |
| `bin/clw` | 在当前目录开新 tmux 窗口启动真彩色 claude，可带交接简报直接开工（任务接力标准入口） | 已加入 PATH（见 `zsh/.zshrc`） |
| `CLAUDE.tmux.md` | 给所有 claude 会话的 tmux 编排约定（显式 -t、接力用 clw、禁 send-keys 注入等） | 需在 `~/.claude/CLAUDE.md` 里 import（待确认） |

相关但不在本目录的配置：

- `~/.claude/settings.json`：`preferredNotifChannel=terminal_bell`（响铃穿透 tmux）、`Bash(tmux *)` 白名单
- `tmux/.tmux.conf`：`allow-passthrough`/`focus-events`/`extended-keys` 四件套（Shift+Enter 与通知透传的基础）
