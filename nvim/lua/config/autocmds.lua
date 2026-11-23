-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- LazyVim 的 lazyvim_wrap_spell 组给 text/plaintex/typst/gitcommit/markdown
-- 同时开 wrap + spell。中文文档在英文拼写检查下满屏红黄波浪线
-- （SpellBad/SpellCap 高亮），纯噪音，这里把 spell 关掉。
-- 只覆盖 spell、不删整组：删组会连 markdown 的 wrap=true 一起删掉，
-- 而全局 wrap 是关的（options.lua），长中文段落会横向跑出屏幕。
-- 本文件在 LazyVim 默认 autocmds 之后加载，同 pattern 的回调后执行、可覆盖。
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
