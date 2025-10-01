local options = {
  ensure_installed = {
    "luadoc",
    "lua",
    "vim",
    "vimdoc",
    "python",
    "go",
    "markdown",
    "markdown_inline",
    "bash",
    "nu",
    "yaml",
    "typescript",
    "javascript",
    "rust",
    "proto",
    "git_config",
    "starlark",
    "asciidoc",
    "asciidoc_inline",
  },

  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true },

  refactor = {
    highlight_definitions = { enable = true },
    highlight_current_scope = { enable = true },
    smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = "grr",
      },
    },
    navigation = {
      enable = true,
      -- Assign keymaps to false to disable them, e.g. `goto_definition = false`.
      keymaps = {
        goto_definition = "gnd",
        list_definitions = "gnD",
        list_definitions_toc = "gO",
        goto_next_usage = "<a-*>",
        goto_previous_usage = "<a-#>",
      },
    },
  },
}

return options
