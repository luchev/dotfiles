local options = {
  formatters_by_ft = {
    lua = { "stylua" },
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
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
}

return options
