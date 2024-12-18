local options = {
  filetype = {
    lua = {
      require("formatter.filetypes.lua").stylua,

      function()
        return {
          exe = "stylua",
          args = {
            "--search-parent-directories",
            "--stdin-filepath",
            util.escape_path(util.get_current_buffer_file_path()),
            "--",
            "-",
          },
          stdin = true,
        }
      end
    },

    ["*"] = {
      require("formatter.filetypes.any").remove_trailing_whitespace,
    },
  }
}

return options
