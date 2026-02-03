local M = {}

M.linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  python = { "flake8" },
  markdown = { "vale" },
  lua = { "selene" },
  go = { "golangcilint" },
  rust = { "clippy" },
}

M.linters = {
  selene = {
    cmd = vim.fn.stdpath("data") .. "/mason/bin/selene",
    stdin = true,
    args = { "--display-style", "quiet", "-" },
    stream = "stdout",
    ignore_exitcode = true,
    parser = require("lint.parser").from_errorformat("%f:%l:%c: %t%*[^:]: %m", {
      source = "selene",
      severity = {
        E = vim.diagnostic.severity.ERROR,
        W = vim.diagnostic.severity.WARN,
      },
    }),
  },
}

return M
