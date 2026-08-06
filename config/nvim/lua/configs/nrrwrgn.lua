local M = {}

M.init = function()
  -- Disable default mappings to avoid conflicts
  vim.g.nrrw_rgn_nomap_nr = 1
  vim.g.nrrw_rgn_nomap_Nr = 1
  -- Use a prominent highlight for the selected region
  vim.g.nrrw_rgn_hl = "IncSearch"
  -- Don't disable highlighting
  vim.g.nrrw_rgn_nohl = 0
  -- Use relative sizing for better responsiveness
  vim.g.nrrw_rgn_resize_window = "relative"
  -- Open as vertical split on the right
  vim.g.nrrw_rgn_vert = 1
  vim.g.nrrw_topbot_leftright = "botright"
  -- Set a good default width (percentage when relative)
  vim.g.nrrw_rgn_wdth = 50
end

M.config = function()
  -- Create a floating window version of NrrwRgn
  vim.api.nvim_create_user_command("NrrwRgnFloat", function()
    -- Get the visual selection range
    local start_line = vim.fn.line "'<"
    local end_line = vim.fn.line "'>"

    -- Execute the narrow region command
    vim.cmd(start_line .. "," .. end_line .. "NR")

    -- Convert the new window to a floating window
    vim.schedule(function()
      local buf = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()

      -- Close the split window
      vim.api.nvim_win_close(win, false)

      -- Calculate centered floating window dimensions
      local width = math.floor(vim.o.columns * 0.7)
      local height = math.floor(vim.o.lines * 0.7)
      local row = math.floor((vim.o.lines - height) / 2)
      local col = math.floor((vim.o.columns - width) / 2)

      -- Create floating window
      local float_win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " Narrow Region ",
        title_pos = "center",
      })

      -- Set window options for better visibility
      vim.api.nvim_set_option_value("winblend", 0, { win = float_win })
      vim.api.nvim_set_option_value("cursorline", true, { win = float_win })
    end)
  end, { range = true })
end

return M
