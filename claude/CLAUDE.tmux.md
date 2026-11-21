# tmux 编排约定（供所有 claude 会话遵守）

## 环境事实

- 用户的终端是 kitty + tmux：kitty 快捷键经 `send_text` 注入「C-Space 前缀 + 命令键」操作 tmux，用户本人从不手按前缀键（物理 Ctrl-Space 被 macOS 输入法占用）
- 会话结构：`tnew <名字>` 创建或打开会话（main 按 `tmux/workspace/[local/]main.conf` 建工作区，local/ 为各机器私有配置不进仓库）；`cmd+n` 新 OS 窗口是裸 zsh（不自动进 tmux，专供 ssh 远程等场景，避免本地/远程 tmux 嵌套）
- 交互式 claude 通过 alias 以 `env -u TMUX claude` 启动（TMUX 变量会让 claude 降级 256 色）；因此进程内 **没有 TMUX 变量但保留 TMUX_PANE**
- claude 状态显示在 tmux 状态栏（hooks + 守护进程驱动）：窗口条目里每个跑 claude 的 pane 一颗彩球——🟢 闪烁=干活中、🔴 快闪=需要用户确认、🟡 常亮=完成或空闲（会话一打开就是黄球，与实体灯 idle 语义一致），闪烁节奏与桌面实体 ESP32 红绿灯（traffic_light 固件 600/180ms）一致；没跑 claude 的 pane/窗口不显示球。早期方案的 pane 边框染色已废弃（会被活动 pane 的蓝色边框覆盖）

## 操作 tmux 的规则

1. tmux 命令已在权限白名单（`Bash(tmux *)`），可直接执行；但因进程内无 TMUX 变量，**所有命令必须显式带 `-t` 目标**（如 `-t main`、`-t "$TMUX_PANE"`），不要依赖「当前」上下文的隐式默认
2. 查看布局用 `tmux list-windows -t main` / `tmux list-panes -t main:窗口 -F '#{pane_index} #{pane_id} #{pane_current_path}'`
3. 用户主会话里做探测/调试时，新建的临时窗口用完必须 `tmux kill-window -t main:名字` 删除，不要留垃圾窗口

## 任务接力（另起单）

1. 需要新会话接续工作时，用 `clw <窗口名> "<交接简报>"`（在 PATH 中）在当前目录开新 tmux 窗口并直接开工；简报要自包含：背景、要做什么、关键文件、验收标准
2. 禁止用 `tmux send-keys` 向另一个**正在运行的交互式 claude 会话**注入文字（无官方保证，会窜键）；拉新会话时把 prompt 作为 clw 参数传入即可
3. 与并行会话协调优先用 ListAgents / SendMessage 跨会话消息（v2.1.224+ 默认开启），可订阅对方空闲通知
4. 脚本化提取历史会话结论用 `claude -p --resume <session-id> --output-format json "..."`（可跨目录）

## 多会话并行的工作区约定

1. 一需求一 git worktree 一窗口一 claude 会话；worktree 目录名保持互不相同
2. 在同一工程目录并行开多个 claude 前，确认各自工作目录（worktree）独立，避免互相踩改动
