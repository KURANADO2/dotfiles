# tmux 工作流与快捷键手册

覆盖三块内容：工作区机制（tnew）、完整快捷键表、架构设计。对应配置：`tmux/.tmux.conf`、`kitty/kitty.conf`（keymaps 段）、`tmux/workspace/new.sh`；claude 会话协作组件（彩球/登记簿/接力）见 [claude/README.md](../claude/README.md)

## 1. 工作区（tnew）

### 1.1 设计理念

- 不自动进 tmux：kitty 启动、`cmd+n` 新 OS 窗口、远程 ssh 登录都是裸 zsh，干活前手动 `tnew <名字>`（两边行为一致）
- `cmd+n` 裸窗口的典型用途：ssh 远程再在远程 `tnew`——本地不在 tmux 里，远程 tmux 就不会嵌套（两层 tmux 前缀键相同，外层会截获按键）
- 已知取舍：裸 zsh 窗口里按 Cmd 系快捷键会把 tmux 前缀字节打进 shell（零星垃圾字符，无实害）

### 1.2 tnew 行为

`tnew <名字>` 是 zsh 函数（定义在 `zsh/.zshrc`），后端为 `tmux/workspace/new.sh`：

1. 会话已存在 → 直接 attach
2. 不存在 → 按 conf 建好整个工作区再 attach
3. 没有对应 conf → 建普通空会话

conf 查找顺序：

1. `tmux/workspace/local/<名字>.conf`——机器私有，gitignore，各机器写自己的
2. `tmux/workspace/<名字>.conf`——仓库通用版（如 `main.conf` 的 8 窗口布局）

conf 格式 = tmux 原生命令逐行书写（new-window / split-window / select-layout…），由 `new.sh` 在「刚创建的会话是最近使用会话」的上下文中 source-file 执行，因此 conf 内的窗口目标可省略会话名（写 `-t :窗口名` 即可）

attach 一律不用 exec：detach（`cmd+d`）后 tmux 客户端退出，当前窗口回到裸 shell 提示符而不是跟着关闭，再次 `tnew <名字>` 即可接回

## 2. 完整快捷键表

三种用法：

1. **macOS + kitty**：直接按「kitty 快捷键」列——kitty 用 `send_text` 注入「前缀字节 + 命令键」，无需手按前缀
2. **ssh 远程（从 Mac kitty 里发起）**：Cmd 快捷键的字节经 ssh 原样透传，同一套键位直接驱动远程 tmux
3. **任意终端**：先按前缀 `C-Space`，再按「前缀命令键」列

「原生默认键」列为 tmux 出厂默认绑定（前缀仍是 `C-b` 时的键位），便于对照 man tmux

### 2.1 窗口（= kitty tab）

| kitty 快捷键 | 前缀命令键 | 功能 | tmux 命令 | 原生默认键 |
|---|---|---|---|---|
| `cmd+t` | `c` | 新建窗口（当前目录） | `new-window -c "#{pane_current_path}"` | `prefix c`（不带路径参数） |
| `cmd+w` | `&` | 关闭窗口（确认弹窗） | `confirm-before kill-window` | `prefix &` |
| `cmd+shift+i` | `,` | 重命名窗口 | `rename-window` | `prefix ,` |
| `ctrl+shift+]` | `n` | 下一个窗口 | `next-window` | `prefix n` |
| `ctrl+shift+[` | `p` | 上一个窗口 | `previous-window` | `prefix p` |
| `cmd+1`~`cmd+9` | `1`~`9` | 直达第 N 个窗口 | `select-window -t N` | `prefix 1..9` |
| `cmd+0` | `0` | 直达第 10 个窗口 | `select-window -t 10`（重绑：base-index 1 后无 0 号窗口） | `prefix 0` |
| `cmd+p` | `L` | 最近用过的窗口 | `last-window` | `prefix l`（此处挪到 L，l 让给 resize） |
| `ctrl+shift+.` | `>` | 窗口右移、焦点跟随 | `swap-window -d -t +1`，末位时改 `move-window -b -t :^` 插入回绕 | 无 |
| `ctrl+shift+,` | `<` | 窗口左移、焦点跟随 | `swap-window -d -t -1`，首位时改 `move-window -a -t :$` 插入回绕 | 无 |

窗口左右移动的边界回绕是插入语义（最后一个右移会整体顺移到第 1 位），对齐 kitty 的 move_tab 手感，实现细节与踩坑记录见 `.tmux.conf` 注释

### 2.2 pane（= kitty window）

| kitty 快捷键 | 前缀命令键 | 功能 | tmux 命令 | 原生默认键 |
|---|---|---|---|---|
| `cmd+enter` | `Enter` | 右侧竖分（当前目录） | `split-window -h -c "#{pane_current_path}"` | `prefix %` |
| — | `%` | 右侧竖分（原生键补上当前路径） | `split-window -h -c` | `prefix %` |
| — | `"` | 上下横分（当前目录）⚠️ 见下方冲突说明 | `split-window -v -c` | `prefix "` |
| `ctrl+cmd+shift+.` | `"` | 把当前 pane 送到右邻窗口 ⚠️ | 设计意图 `move-pane -t :{next}`，当前被上行覆盖 | 无 |
| `ctrl+cmd+shift+,` | `'` | 把当前 pane 送到左邻窗口 | `move-pane -t :{previous}` | 无 |
| `cmd+shift+]` | `o` | 下一个 pane（缩放态保持缩放） | `select-pane -t :.+ -Z` | `prefix o`（原生不带 -Z） |
| `cmd+shift+[` | `O` | 上一个 pane（缩放态保持缩放） | `select-pane -t :.- -Z` | 无 |
| `cmd+shift+.` | `}` | 与下一个 pane 换位 | `swap-pane` | `prefix }` |
| `cmd+shift+,` | `{` | 与上一个 pane 换位 | `swap-pane` | `prefix {` |
| `cmd+shift+x` | `x` | 关闭当前 pane（确认弹窗） | `confirm-before kill-pane` | `prefix x` |

> ⚠️ 已知冲突：`"` 在 `.tmux.conf` 里被绑定了两次（`move-pane` 送右邻在前、`split-window -v` 补路径在后），后者生效——因此 `ctrl+cmd+shift+.` 当前实际行为是上下横分，而不是设计意图的「送 pane 到右邻窗口」。待修复，修复后更新本表

### 2.3 布局

| kitty 快捷键 | 前缀命令键 | 功能 | tmux 命令 | 原生默认键 |
|---|---|---|---|---|
| `cmd+shift+=` | `z` | 当前 pane 缩放开关（≈ kitty stack） | `resize-pane -Z` | `prefix z` |
| `cmd+shift+t` | `t` | tall：左一大列右一小列 | `select-layout main-vertical` | `M-4` |
| `cmd+shift+f` | `f` | fat：上一大行下一小行 | `select-layout main-horizontal` | `M-3` |
| `cmd+shift+g` | `g` | grid 网格平铺 | `select-layout tiled` | `M-5` |
| `cmd+shift+-` | `-` | 单列上下排 | `select-layout even-vertical` | `M-2` |
| `cmd+shift+\` | `\` | 单行左右排 | `select-layout even-horizontal` | `M-1` |
| — | `Space` | 循环切换布局 | `next-layout` | `prefix Space` |

`M-1`~`M-5`（Alt + 数字）的原生预设绑定全部保留

### 2.4 pane 尺寸调整（vim 式 hjkl）

语义与 tmux 原生 `M-方向键` 完全一致：按哪个方向，可动的边界就朝哪边挪，步进 3 格

| kitty 快捷键 | 前缀命令键 | 功能 | tmux 命令 | 原生默认键 |
|---|---|---|---|---|
| `cmd+shift+h` | `h` | 边界左移 | `resize-pane -L 3` | `M-Left` |
| `cmd+shift+j` | `j` | 边界下移 | `resize-pane -D 3` | `M-Down` |
| `cmd+shift+k` | `k` | 边界上移 | `resize-pane -U 3` | `M-Up` |
| `cmd+shift+l` | `l` | 边界右移 | `resize-pane -R 3` | `M-Right`（l 原为 next-layout，已让位） |
| `ctrl+opt+r` | `R` | 重置：pane 尺寸重新均匀铺开 | `select-layout -E` | 无 |

### 2.5 会话 / 浮层 / 功能键

| kitty 快捷键 | 前缀命令键 | 功能 | tmux 命令 | 原生默认键 |
|---|---|---|---|---|
| `cmd+d` | `d` | 脱离当前会话（转后台，窗口回裸 zsh） | `detach-client` | `prefix d` |
| `cmd+shift+p` | `P` | 浮动 shell 浮层（85% 居中，exit 或 q 关闭） | `display-popup -w 85% -h 85% -d "#{pane_current_path}"` | 无 |
| `F1` | `F1` | 广播输入开关：本窗口所有 pane 收到相同按键（批量给多个 claude 下指令），状态栏右下角显示「📢 广播中」 | `set synchronize-panes` | 无 |
| `F2` | `F2` | claude 会话谱系树浮层：彩球 + ↳代数标记，输入编号跳转对应 pane（后端 `claude/bin/clw-tree`） | `display-popup -w 85% -h 85% -E "python3 …/clw-tree"` | 无 |

### 2.6 保留给 kitty 的键（macOS OS 级，tmux 管不到）

| 快捷键 | 功能 |
|---|---|
| `cmd+n` | 新 OS 窗口（裸 zsh，不自动进 tmux——ssh 远程等场景专用） |
| `cmd+r` | 拖拽调整 OS 窗口大小 |
| `ctrl+cmd+,` | 重载 kitty 配置 |

### 2.7 保留的原生能力

1. 鼠标（`mouse on`）：滚轮回滚历史、点击选 pane、拖拽调大小
2. copy-mode 用 vi 键位：`v` 选择、`y` 复制，经 OSC 52 写系统剪贴板（`set-clipboard on`）
3. 回滚缓冲每 pane 10 万行（`history-limit 100000`）
4. 窗口从 1 编号（`base-index 1`），关窗后自动重排不留空洞（`renumber-windows on`）
5. `escape-time 10`：消除 nvim 按 Esc 的延迟

## 3. 架构设计

### 3.1 分工

- kitty 只管 OS 窗口与渲染；tab/分屏/布局/会话持久全部由 tmux 承担
- 远程服务器只需 tmux 即可获得与本机一致的操作手感——ssh 透传按键字节，外层终端是什么并不重要

### 3.2 免前缀原理

kitty 快捷键用 `send_text` 把「tmux 前缀字节 `\x00`（= C-Space）+ 命令键」写进终端数据流，由 tmux 解释执行，你永远不用手按前缀键。前缀设为 `C-Space` 但物理 Ctrl-Space 被 macOS 系统层拦截用于切输入法（到不了终端），两条通路互不干扰

维护须知：

1. `send_text` 的值是「到行尾为止的全部文本」，**不支持行尾注释**——同一行 `#` 后面的内容会被当成按键打进终端，注释必须独立成行
2. `kitty.conf` 每条映射注明实际执行的 tmux 命令与原生默认键；`.tmux.conf` 自定义绑定同样注明原始命令，两边对照改
3. 终端协议四件套（`allow-passthrough` / `focus-events` / `extended-keys` / `terminal-features`）是 Claude Code 官方 terminal-config 的要求，Shift+Enter 修复与桌面通知透传的基础
4. `COLORTERM=truecolor` 由 tmux 全局环境注入：ssh 登录不会携带该变量，缺它时 claude/nvim 会保守降级 256 色

### 3.3 远程复用与断线恢复

- ssh 登录远程后是裸 shell（与本机一致），手动 `tnew` 进远程自己的 tmux 会话；本机全部 Cmd 快捷键经 ssh 原样透传，直接驱动远程 tmux
- 远程会话不怕断网：重连后 `tnew main` 即恢复现场
- 要求远程 tmux ≥ 3.3（`allow-passthrough` 需要）；部署步骤见 [docs/remote-server.md](remote-server.md)
