local M = {}

M.linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  python = { "flake8" },
  markdown = { "vale" },
  lua = { "luacheck" },
}

M.linters = {
  luacheck = {
    cmd = "luacheck",
    stdin = true,
    args = {
      "--globals",
      "vim",
      "lvim",
      "reload",
      "--",
    },
    stream = "stdout",
    ignore_exitcode = true,
    parser = require("lint.parser").from_errorformat("%f:%l:%c: %m", {
      source = "luacheck",
    }),
  },
}

return M
