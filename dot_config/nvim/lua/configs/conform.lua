local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    kdl = { "kdlfmt" },
    python = { "isort", "black" },
    rust = { "rustfmt", lsp_format = "fallback" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    go = { "goimports-reviser", "gofumpt", "golines" },
    ["*"] = { "codespell" },
    ["_"] = { "trim_whitespace" },
  },
  formatters = {
    ["goimports-reviser"] = {
      prepend_args = { "-format", "-rm-unused", "-set-alias" },
    },
  },
}

return options
