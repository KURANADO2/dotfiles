if vim.fn.has("mac") == 1 then
  return {
    "keaising/im-select.nvim",
    config = function()
      -- 插件在 macOS 上默认使用 macism(arm64 原生),旧的 im-select 是 x86_64 已无法运行
      require("im_select").setup({})
    end,
  }
else
  return {}
end
