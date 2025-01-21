local options = {
  defaults = {
    vimgrep_arguments = {
      "rg",
      "-L",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
    },
  },
  extensions_list = { "themes", "terms", "file_browser", "dap", "frecency", "luasnip", "gpt", "live_grep_args" },
}

return options
