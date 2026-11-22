# claude × tmux 协作组件

第二批「tmux + claude code 联动」的落地文件，以及第三批「待办登记簿 + 任务接力」功能包。安装与配置状态见各文件头注释。

| 文件 | 作用 | 生效方式 |
|---|---|---|
| `hooks/tmux-status.sh` | 记录 pane 级 claude 状态（`@claude_state`，附 `@claude_session_id` / `@claude_state_ts` 供纠偏）并踢起彩球守护进程，claude hooks 调用 | `~/.claude/settings.json` 的 hooks 段（已配置） |
| `hooks/tmux-balls-daemon.py` | 状态栏彩球守护：60ms 相位循环，按 traffic_light 固件节奏（绿 600ms 闪/红 180ms 快闪/黄常亮）把各窗口的彩球串写入 `@claude_balls`；每 3 秒用 `claude agents --json` 按 sessionId 纠偏 pane 状态（hook 漏事件/进程被杀时兜底）；每 3 秒统计待办登记簿未关闭条目数写入 `@followups_count`（状态栏右下角 🔔N）；无状态 5 秒自动退出，文件锁单实例 | 由 tmux-status.sh 自动拉起；`window-status-format` / `status-right` 引用（已配置） |
| `hooks/followups-reminder.sh` | SessionStart 开门播报：解析项目名（worktree 归一到主仓库名），本项目登记簿有未关闭待办则把清单注入会话上下文，无则静默 | `~/.claude/settings.json` 的 SessionStart hooks（已配置） |
| `skills/handoff/SKILL.md` | 任务接力规程：四段式交接简报 → 登记簿标 `[handed-off(窗口名)]` → `clw --brief-file` 拉起新窗口 → 简报附销单职责 | `~/.claude/skills` 软链到本目录（install.sh） |
| `bin/clw` | 在当前目录开新 tmux 窗口启动真彩色 claude，可带交接简报直接开工；`--brief-file <路径>` 从文件读简报（超长简报免转义，handoff skill 标准用法） | 已加入 PATH（见 `zsh/.zshrc`） |
| `CLAUDE.tmux.md` | 给所有 claude 会话的 tmux 编排约定（显式 -t、接力走 handoff skill、禁 send-keys 注入等）与**待办登记簿硬规则**（「建议另起单」必须登记 `[open]` 条目、修复方销单） | 需在 `~/.claude/CLAUDE.md` 里 import（已配置） |

## 待办登记簿（followups）

跨会话待办台账：`~/.claude/followups/<项目名>.md`（仓库外集中存放，install.sh 建目录）。闭环：

1. 会话结论写「建议另起单」→ 按 `CLAUDE.tmux.md` 的模板追加 `[open]` 条目（硬规则）
2. 交接 → handoff skill 生成四段式简报、条目标 `[handed-off(窗口名)]`、`clw --brief-file` 拉起新窗口
3. 修复完成 → 接手会话把条目改 `[done]` 销单（简报末尾附带的职责）

两条自动化联动：SessionStart 开门播报（`followups-reminder.sh`，本项目未关闭条目注入上下文）；状态栏 🔔N 计数（彩球守护进程写 `@followups_count`，`status-right` 显示在广播指示器前面，N=0 时消失）。

相关但不在本目录的配置：

- `~/.claude/settings.json`：`preferredNotifChannel=terminal_bell`（响铃穿透 tmux）、`Bash(tmux *)` 白名单
- `tmux/.tmux.conf`：`allow-passthrough`/`focus-events`/`extended-keys` 四件套（Shift+Enter 与通知透传的基础）；`status-right` 引用 `#{@followups_count}`
