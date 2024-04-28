return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    { "q", "<cmd>BufferLineClose<cr>", desc = "Close Buffer" },
    { "E", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "R", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "W", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "First Buffer" },
    { "T", "<cmd>BufferLineGoToBuffer -1<cr>", desc = "Last Buffer" },
  },
}
