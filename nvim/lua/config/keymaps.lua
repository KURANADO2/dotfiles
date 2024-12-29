-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 复用 opt 参数
local opt = { noremap = true, silent = true }

-- 取消 s 默认功能
vim.keymap.set("n", "s", "", opt)

-- 窗口分割
vim.keymap.set("n", "sh", ":set nosplitright<CR>:vsplit<CR>", opt)
vim.keymap.set("n", "sj", ":set splitbelow<CR>:split<CR>", opt)
vim.keymap.set("n", "sk", ":set nosplitbelow<CR>:split<CR>", opt)
vim.keymap.set("n", "sl", ":set splitright<CR>:vsplit<CR>", opt)

-- 窗口跳转
vim.keymap.set("n", "<LEADER>h", "<C-w>h", opt)
vim.keymap.set("n", "<LEADER>j", "<C-w>j", opt)
vim.keymap.set("n", "<LEADER>k", "<C-w>k", opt)
vim.keymap.set("n", "<LEADER>l", "<C-w>l", opt)

-- 窗口比例调整
vim.keymap.set("n", "<up>", ":res +5<CR>", opt)
vim.keymap.set("n", "<down>", ":res -5<CR>", opt)
vim.keymap.set("n", "<left>", ":vertical resize-5<CR>", opt)
vim.keymap.set("n", "<right>", ":vertical resize+5<CR>", opt)

-- 光标移动
vim.keymap.set("", "<C-h>", "^", opt)
vim.keymap.set("", "<C-j>", "5j", opt)
vim.keymap.set("", "<C-k>", "5k", opt)
vim.keymap.set("", "<C-l>", "$", opt)

-- insert 模式下，跳到行首行尾
vim.keymap.set("i", "<C-h>", "<ESC>I", opt)
vim.keymap.set("i", "<C-l>", "<ESC>A", opt)

-- 对调行模式和块模式
vim.keymap.set("n", "<C-v>", "V", opt)
vim.keymap.set("", "V", "<C-v>", opt)

-- 选中文本
vim.keymap.set("", "v<C-h>", "v^", opt)
vim.keymap.set("", "v<C-l>", "v$h", opt)
vim.keymap.set("", "vie", "ggVG", opt)

-- 上下翻页
vim.keymap.set("n", "J", "5<C-e>", opt)
vim.keymap.set("n", "K", "5<C-y>", opt)
-- 左右翻页
vim.keymap.set("n", "H", "50zh", opt)
vim.keymap.set("n", "L", "50zl", opt)

-- 在代码行末尾补全分号
vim.keymap.set("n", "<LEADER>;", "A;<ESC>", opt)

-- 大小写
vim.keymap.set("", "`", "~", opt)

-- 替换
vim.keymap.set("n", "\\s", ":%s/\\v//g<left><left><left>")

-- 删除文件中所有空行
vim.keymap.set("n", "\\d", ":g/^\\s*$/d<CR>")

-- rest http
vim.keymap.set("n", "<C-M>", ":Rest run<CR>")

-- 录制宏
vim.keymap.set("n", "sm", "q", opt)

-- 重做
vim.keymap.set("n", "U", "<C-r>", opt)

-- 保存 Buffer
vim.keymap.set("", "S", ":w<CR>", opt)

-- 关闭 Buffer
vim.keymap.set("", "q", ":bd<CR>", opt)

-- 退出
vim.keymap.set("", "Q", ":q<CR>", opt)
