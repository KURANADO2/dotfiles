return {
  "nvim-lualine/lualine.nvim",
  config = function()
    require("lualine").setup({
      sections = {
        lualine_x = {
          {
            "rest",
            icon = "",
            fg = "#428890",
          },
        },
      },
    })
  end,
}
