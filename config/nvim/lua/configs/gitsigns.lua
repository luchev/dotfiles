local options = {
  signs = {
    add = { text = "│" },
    change = { text = "│" },
    delete = { text = "󰍵" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "│" },
  },
  on_attach = function(bufnr)
    -- Add alias for :Gitsigns
    vim.cmd [[ cnoreabbrev GS Gitsigns ]]

    local gitsigns = require("gitsigns")

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- map("n", "]c", function()
    --   if vim.wo.diff then
    --     vim.cmd.normal { "]c", bang = true }
    --   else
    --     gitsigns.nav_hunk "next"
    --   end
    -- end, { desc = "gitsigns next hunk" })
    --
    -- map("n", "[c", function()
    --   if vim.wo.diff then
    --     vim.cmd.normal { "[c", bang = true }
    --   else
    --     gitsigns.nav_hunk "prev"
    --   end
    -- end, { desc = "gitsigns prev hunk" })

    map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "gitsigns reset hunk" })
    map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "gitsigns preview hunk" })
    map("n", "<leader>hb", function()
      gitsigns.blame_line { full = true }
    end, { desc = "gitsigns blame line" })
    map("n", "<leader>hb", gitsigns.toggle_current_line_blame, { desc = "gitsigns toggle current line blame" })
    map("n", "<leader>hd", gitsigns.diffthis, { desc = "gitsigns diff this" })
    map("n", "<leader>hD", function()
      gitsigns.diffthis "~"
    end, { desc = "gitsigns diff this" })
  end,
}

return options
