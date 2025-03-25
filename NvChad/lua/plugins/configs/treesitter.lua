local map = {

  options = {

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
      "yaml",
      "typescript",
      "javascript",
      "rust",
      "proto",
      "git_config",
      "nu",
      "just",
    },

    highlight = {
      enable = true,
      use_languagetree = true,
    },

    indent = { enable = true },
  },
}

return map
