-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Size of an indent
vim.opt.shiftwidth = 4
-- Number of spaces tabs count for
vim.opt.tabstop = 4
-- Nowrap
vim.opt.wrap = false
vim.opt.jumpoptions = "stack"

-- 剪贴板：覆盖 LazyVim 对 SSH 的保守判断（lazyvim/config/options.lua 里
-- `opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"`，远程一律置空）。
-- 置空的后果是 y 只进本进程的内部寄存器，跨 pane 的另一个 nvim 读不到。
-- 这台机器上 nvim 挑中的 provider 是 tmux：写用 `tmux load-buffer -w -`，
-- 读用 `tmux save-buffer -`。于是 namedplus 一次解决两件事：
--   1. tmux buffer 是 server 级共享，同一 tmux 内所有 nvim 实例互相可见
--   2. -w 会经 OSC 52 把内容推到外层终端（kitty）→ Mac 系统剪贴板
--      （依赖 .tmux.conf 的 `set-clipboard on` 与 kitty 默认允许写剪贴板）
-- 放这里有效：LazyVim 的 M.load("options") 先加载自己那份、再加载本文件，
-- 之后把结果存进 lazy_clipboard，到 User VeryLazy 才写回 vim.opt.clipboard
-- 注意反向不通：Mac 上复制的内容进不了 "+p（tmux 只代理 OSC 52 的写，
-- 不代理读），那条路要用终端自己的粘贴（kitty Cmd+V）
vim.opt.clipboard = "unnamedplus"

-- 补丁：TMUX 变量被剥掉、但实际仍在 tmux 里的场景（特征：TMUX_PANE 还在）。
-- 典型来源是 claude code 的 alias `env -u TMUX claude`（防 claude 降级 256 色），
-- ctrl+o → v 用它拉起的 nvim 看会话记录时，环境里没有 TMUX。此时上面那条链
-- 两头全断：自动探测的 tmux provider 要求 $TMUX 非空（clipboard.vim 258 行），
-- OSC 52 兜底又要求 clipboard 为空（260 行，被上面的 unnamedplus 挡掉），
-- 结果 provider 为空，y 只进内部寄存器，复制不到 Mac。
-- 显式指定字符串形式的 g:clipboard，走和自动探测完全相同的 s:set_tmux()
if not vim.env.TMUX and vim.env.TMUX_PANE then
  vim.g.clipboard = "tmux"
end
