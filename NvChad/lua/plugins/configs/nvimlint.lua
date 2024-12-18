vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    require("lint").try_lint()
  end,
})

local linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  python = { "flake8" },
  markdown = { "vale" },
  lua = { "luacheck" },
}

return linters_by_ft
