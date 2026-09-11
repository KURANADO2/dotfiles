-- LSP keymaps
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          inlay_hints = {
            enabled = true,
          },
          ["rust_analyzer"] = {
            settings = { allFeatures = true },
          },
          keys = {
            { "K", false },
          },
        },
      },
    },
  },
}
