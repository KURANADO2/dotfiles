# claude × tmux 协作组件

第二批「tmux + claude code 联动」的落地文件。安装与配置状态见各文件头注释。

| 文件 | 作用 | 生效方式 |
|---|---|---|
| `hooks/tmux-status.sh` | pane 边框状态灯（绿=干活/红=需确认/黄=完成，与实体红绿灯同语义），claude hooks 调用 | `~/.claude/settings.json` 的 hooks 段（已配置） |
| `bin/clw` | 在当前目录开新 tmux 窗口启动真彩色 claude，可带交接简报直接开工（任务接力标准入口） | 已加入 PATH（见 `zsh/.zshrc`） |
| `CLAUDE.tmux.md` | 给所有 claude 会话的 tmux 编排约定（显式 -t、接力用 clw、禁 send-keys 注入等） | 需在 `~/.claude/CLAUDE.md` 里 import（待确认） |

相关但不在本目录的配置：

- `~/.claude/settings.json`：`preferredNotifChannel=terminal_bell`（响铃穿透 tmux）、`Bash(tmux *)` 白名单
- `tmux/.tmux.conf`：`allow-passthrough`/`focus-events`/`extended-keys` 四件套（Shift+Enter 与通知透传的基础）
