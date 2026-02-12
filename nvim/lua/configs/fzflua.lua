return function()
  require("fzf-lua").setup {
    defaults = { git_icons = false },
  }

  vim.api.nvim_create_user_command("F", function(opts)
    vim.cmd("FzfLua " .. opts.args)
  end, {
    nargs = "*",
    complete = function(ArgLead, CmdLine, CursorPos)
      return vim.fn.getcompletion("FzfLua " .. ArgLead, "cmdline")
    end,
  })
end
