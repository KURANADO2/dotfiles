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
