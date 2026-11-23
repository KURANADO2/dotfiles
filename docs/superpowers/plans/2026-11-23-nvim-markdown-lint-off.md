# nvim 关闭 markdown 警告 —— 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 打开任何 markdown 文件不再出现 markdownlint 警告，其余 markdown 功能（render-markdown 渲染美化、markdown-preview 预览、marksman 跳转、prettier 格式化）保持不变

**Architecture:** 在用户插件目录 `nvim/lua/plugins/` 新增一个 lazy spec，用函数形式 opts 把 lang.markdown 扩展注册到 nvim-lint 的 markdown linter 列表清空。不删插件、不改 lockfile

**Tech Stack:** LazyVim / lazy.nvim / nvim-lint / markdownlint-cli2（被移除的诊断源）

**Spec:** `docs/superpowers/specs/2026-11-23-nvim-markdown-lint-off-design.md`

## Global Constraints

- 禁止改动 `nvim/lazy-lock.json`（按用户约定 lockfile 只在 Mac 端更新提交）
- 禁止增删插件，只允许 opts 覆盖
- 在 worktree 分支 `worktree-nvim-markdown-lint-off` 开发，完成后合入 main，永不 push
- 验证一律用 headless nvim 实测诊断数与插件清单，不以「配置看起来对」为准

## Review Focus

1. 函数形式 opts 未按预期生效（lazy 合并时机/语义与预期不符，linter 仍在跑）→ Task 1 Step 3 的 0 诊断实测覆盖
2. 新增 lua 文件语法错误导致 nvim 启动报错 → Task 1 Step 3 命令输出中无 Lua 错误覆盖
3. markdown.mdx 文件类型回归：nvim-lint 对 `markdown.mdx` 按 `.` 拆分后命中 markdown 的 linter 列表，清空后同样安静 → Task 1 Step 3 对 mdx 样例复测覆盖
4. render-markdown / markdown-preview / nvim-lint 插件本体仍在加载（只清 linter 映射，不禁插件）→ Task 2 Step 3 插件清单检查覆盖
5. 合并后主 checkout（`~/.config/nvim` 软链目标）行为与工作树验证一致 → Task 2 Step 3 去掉 XDG 覆盖用真实配置复测覆盖

---

### Task 1: 新增 markdown.lua 覆盖并实测验证（worktree 内）

**Files:**
- Create: `nvim/lua/plugins/markdown.lua`
- Test: 无测试框架，用 headless nvim 诊断计数命令充当测试；样例文件 `/tmp/mdtest/test.md`、`/tmp/mdtest/test.mdx`

**Interfaces:**
- Consumes: LazyVim `linting.lua` 的 config 函数最终执行 `lint.linters_by_ft = opts.linters_by_ft`；`lang.markdown` 扩展已注册 `linters_by_ft.markdown = { "markdownlint-cli2" }`；用户插件目录 `{ import = "plugins" }` 在 LazyVim 之后加载，故函数形式 opts 最后执行
- Produces: 生效的配置改动（Task 2 直接合并）；验证命令供 Task 2 复用

- [ ] **Step 1: 准备样例并跑基线（红）**

样例若不存在则重建（内含触发 MD033 的 `<details>` 标签与触发 MD024 的重复标题）：

```bash
mkdir -p /tmp/mdtest && cat > /tmp/mdtest/test.md <<'EOF'
# 测试文档

<details><summary>点击展开</summary>

一些内容

</details>

## 小节

列表与正文。

## 小节

重复的标题也会报警告。
EOF
cp /tmp/mdtest/test.md /tmp/mdtest/test.mdx
```

对 worktree 配置跑基线（修改前，预期出警告）：

```bash
cd /tmp/mdtest && XDG_CONFIG_HOME=/home/jing/github/dotfiles/.claude/worktrees/nvim-markdown-lint-off \
  timeout 60 nvim --headless -c "edit /tmp/mdtest/test.md" \
  -c "lua vim.wait(5000, function() return #vim.diagnostic.get(0) > 0 end, 100)" \
  -c "lua local d = vim.diagnostic.get(0); print(#d .. ' diagnostics'); for _, x in ipairs(d) do print((x.source or '?') .. ' L' .. (x.lnum + 1) .. ': ' .. x.message) end" \
  -c "qa!" 2>&1
```

预期：`3 diagnostics`，全部 source 为 markdownlint（红，证明诊断源与验证命令有效）

- [ ] **Step 2: 写 `nvim/lua/plugins/markdown.lua`**

```lua
-- lang.markdown 扩展通过 nvim-lint 给 markdown 挂了 markdownlint-cli2，
-- 样式规则警告（内联 HTML、重复标题、行超长等）对日常笔记是纯噪音，整体关掉。
-- 必须用函数形式 opts：lazy 对表形式做深合并，markdown = {} 清不掉已注册的列表；
-- 函数形式在全部 spec 合并后执行，直接赋值才能真正覆盖。
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
    end,
  },
}
```

- [ ] **Step 3: 复跑验证命令（绿）**

用 Step 1 的同一命令，把 `edit` 的文件分别换成 `/tmp/mdtest/test.md` 与 `/tmp/mdtest/test.mdx`。

预期：两个文件均输出 `0 diagnostics`，输出中无 Lua 报错。（0 诊断时 `vim.wait` 条件永不满足会等满 5 秒才继续，属预期，不是卡死）

- [ ] **Step 4: 提交**

```bash
git add nvim/lua/plugins/markdown.lua
git commit -m "fix(nvim): 关闭 markdown 文件的 markdownlint 诊断警告"
```

### Task 2: 文档提交、合入 main、真机验证

**Files:**
- Commit: `docs/superpowers/specs/2026-11-23-nvim-markdown-lint-off-design.md`、`docs/superpowers/plans/2026-11-23-nvim-markdown-lint-off.md`（worktree 内）
- Modify: 主 checkout `/home/jing/github/dotfiles` 的 main 分支（合并 worktree 分支）

**Interfaces:**
- Consumes: Task 1 的提交与验证命令
- Produces: main 上生效的配置——`~/.config/nvim` 软链指向主 checkout，合并即对本机生效；Mac 端 pull 后同步

- [ ] **Step 1: 提交文档（worktree 内）**

```bash
git add docs/superpowers/
git commit -m "docs(nvim): markdown 警告关闭的设计说明与实施计划"
```

- [ ] **Step 2: 合入 main（用 `git -C` 指向主 checkout，不离开 worktree 会话）**

```bash
git -C /home/jing/github/dotfiles pull origin main
git -C /home/jing/github/dotfiles merge worktree-nvim-markdown-lint-off
```

预期：本次为纯新增文件，无冲突；有冲突则当场解决后按 Global Constraints 验证。不 push

- [ ] **Step 3: 用真实配置复测（合并后 `~/.config/nvim` 已含改动）**

去掉 `XDG_CONFIG_HOME` 覆盖，跑与 Task 1 Step 3 相同的命令（test.md 与 test.mdx）。预期：均 `0 diagnostics`。

再查插件清单未误伤：

```bash
timeout 60 nvim --headless -c 'lua local found = {}; for _, p in ipairs(require("lazy").plugins()) do found[p.name] = true end; print(vim.inspect({ ["render-markdown.nvim"] = found["render-markdown.nvim"] or false, ["markdown-preview.nvim"] = found["markdown-preview.nvim"] or false, ["nvim-lint"] = found["nvim-lint"] or false }))' -c 'qa!' 2>&1
```

预期：三者均 `true`

- [ ] **Step 4: ExitWorktree（remove）**

worktree 内已无未提交改动（Step 1 完成提交），选 remove 清理工作树与分支
