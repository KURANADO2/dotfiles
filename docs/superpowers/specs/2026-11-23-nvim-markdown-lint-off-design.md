# nvim 关闭 markdown 警告 —— 设计说明

## 1. 背景与目标

nvim 打开 markdown 文档时正文里冒出大量警告，显得很乱。来源已实测确认：LazyVim 的 `lang.markdown` 扩展通过 nvim-lint 挂了 markdownlint-cli2，每次打开文件、保存、退出插入模式都会对全文跑一遍「排版规则」检查（内联 HTML、重复标题、行超长之类），命中即插入诊断警告。对日常笔记场景，这些规则是纯噪音。

目标：打开任何 md 文件，不再出现 markdownlint 警告。

非目标：不动 render-markdown（正文美化渲染）、markdown-preview（浏览器预览）、marksman（标题跳转与补全）——这三者不产生警告，功能保留。prettier 对 markdown 的格式化行为也保持不变。

## 2. 方案取舍

1. 从 nvim-lint 中移除 markdownlint（已选定）：新增 `nvim/lua/plugins/markdown.lua`，把 markdown 文件类型的 linter 列表清空。改动最小、干净、可随时删文件恢复。副作用：conform 格式化链里的 markdownlint-cli2 自动修复器因「检测不到 markdownlint 诊断」而永远跳过（其触发条件就是存在 markdownlint 诊断），prettier 格式化照常。
2. 只禁用吵闹规则：markdownlint-cli2 没有官方的全局配置机制（配置从文件所在目录向上查找），需给 linter 强行指定配置路径，实现绕；且未禁用的规则将来仍可能冒新警告。放弃。
3. 仅隐藏诊断显示：后台 lint 照常运行白花 CPU，且会把 marksman 的诊断一并藏掉，治标不治本。放弃。

实现要点：opts 必须写成函数形式（`opts = function(_, opts)`）。lazy.nvim 对表形式 opts 做深合并时无法「清空」已合并的数组——写 `markdown = {}` 合并后原列表元素仍在；只有函数形式里直接赋值才能真正覆盖掉扩展注册的 linter。

## 3. 验证方式

1. 修改前已用 headless nvim 实测样例 md（含 `<details>` 标签与重复标题）：出现 3 条 markdownlint 诊断，复现成功。
2. 修改后以同一命令重跑，预期 0 条诊断。
3. 合入 main 后确认 nvim 正常启动、marksman / render-markdown / markdown-preview 插件仍加载。

## 4. 影响范围

改动只在 dotfiles 仓库。合入 main 后本机立即生效（`~/.config/nvim` 软链指向主工作目录）；Mac 端 pull 后即同步。不新增插件、不动 lazy-lock.json（按约定 lockfile 只在 Mac 更新提交）。
