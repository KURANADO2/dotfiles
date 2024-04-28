return {
  "ggandor/flit.nvim",
  enabled = true,
  keys = function()
    ---@type LazyKeys[]
    local ret = {}
    for _, key in ipairs({ "f", "F" }) do
      ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
    end
    -- Disable the t and T
    for _, key in ipairs({ "t", "T" }) do
      ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key, false }
    end
    return ret
  end,
  opts = { labeled_modes = "nx" },
}
