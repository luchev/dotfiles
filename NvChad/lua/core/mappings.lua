-- n, v, i, t = mode names

local M = {}

M.general = {
  i = {
    -- go to  beginning and end
    ["<C-b>"] = { "<ESC>^i", "Beginning of line" },
    ["<C-e>"] = { "<End>", "End of line" },

    -- navigate within insert mode
    ["<C-h>"] = { "<Left>", "Move left" },
    ["<C-l>"] = { "<Right>", "Move right" },
    ["<C-j>"] = { "<Down>", "Move down" },
    ["<C-k>"] = { "<Up>", "Move up" },
  },

  n = {
    ["<Esc>"] = { "<cmd> noh <CR>", "Clear highlights" },
    -- switch between windows
    ["<C-h>"] = { "<C-w>h", "Window left" },
    ["<C-l>"] = { "<C-w>l", "Window right" },
    ["<C-j>"] = { "<C-w>j", "Window down" },
    ["<C-k>"] = { "<C-w>k", "Window up" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },

    -- Copy all
    ["<C-c>"] = { "<cmd> %y+ <CR>", "Copy whole file" },

    -- line numbers
    ["<leader>n"] = { "<cmd> set nu! <CR>", "Toggle line number" },
    ["<leader>rn"] = { "<cmd> set rnu! <CR>", "Toggle relative number" },

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using <cmd> :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },

    -- new buffer
    ["<leader>b"] = { "<cmd> enew <CR>", "New buffer" },
    ["<leader>ch"] = { "<cmd> NvCheatsheet <CR>", "Mapping cheatsheet" },

    ["<leader>fm"] = {
      function()
        vim.lsp.buf.format { async = true }
      end,
      "LSP formatting",
    },
  },

  t = {
    ["<C-x>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
  },

  v = {
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["<"] = { "<gv", "Indent line" },
    [">"] = { ">gv", "Indent line" },
  },

  x = {
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },
  },
}

M.tabufline = {
  plugin = true,

  n = {
    -- cycle through buffers
    ["<tab>"] = {
      function()
        require("nvchad.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },

    ["<S-tab>"] = {
      function()
        require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },

    -- close buffer + hide terminal buffer
    ["<leader>x"] = {
      function()
        require("nvchad.tabufline").close_buffer()
      end,
      "Close buffer",
    },
  },
}

M.comment = {
  plugin = true,

  -- toggle comment in both modes
  n = {
    ["<leader>/"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "Toggle comment",
    },
  },

  v = {
    ["<leader>/"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "Toggle comment",
    },
  },
}

M.lspconfig = {
  plugin = true,

  -- See `<cmd> :help vim.lsp.*` for documentation on any of the below functions

  n = {
    ["gD"] = {
      function()
        vim.lsp.buf.declaration()
      end,
      "LSP declaration",
    },

    ["gd"] = {
      function()
        vim.lsp.buf.definition()
      end,
      "LSP definition",
    },

    ["K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      "LSP hover",
    },

    ["gi"] = {
      function()
        vim.lsp.buf.implementation()
      end,
      "LSP implementation",
    },

    ["<leader>ls"] = {
      function()
        vim.lsp.buf.signature_help()
      end,
      "LSP signature help",
    },

    ["<leader>D"] = {
      function()
        vim.lsp.buf.type_definition()
      end,
      "LSP definition type",
    },

    ["<leader>ra"] = {
      function()
        require("nvchad.renamer").open()
      end,
      "LSP rename",
    },

    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "LSP code action",
    },

    ["gr"] = {
      function()
        vim.lsp.buf.references()
      end,
      "LSP references",
    },

    ["<leader>lf"] = {
      function()
        vim.diagnostic.open_float { border = "rounded" }
      end,
      "Floating diagnostic",
    },

    ["[d"] = {
      function()
        vim.diagnostic.goto_prev { float = { border = "rounded" } }
      end,
      "Goto prev",
    },

    ["]d"] = {
      function()
        vim.diagnostic.goto_next { float = { border = "rounded" } }
      end,
      "Goto next",
    },

    ["<leader>q"] = {
      function()
        vim.diagnostic.setloclist()
      end,
      "Diagnostic setloclist",
    },

    ["<leader>wa"] = {
      function()
        vim.lsp.buf.add_workspace_folder()
      end,
      "Add workspace folder",
    },

    ["<leader>wr"] = {
      function()
        vim.lsp.buf.remove_workspace_folder()
      end,
      "Remove workspace folder",
    },

    ["<leader>wl"] = {
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      "List workspace folders",
    },

    ["<leader>."] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "",
    },
  },

  v = {
    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "LSP code action",
    },
  },
}

M.nvimtree = {
  plugin = true,

  n = {
    -- toggle
    ["<C-n>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },

    -- focus
    ["<leader>e"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
  },
}

M.telescope = {
  plugin = true,

  n = {
    -- find
    ["<leader>tf"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    ["<leader>ta"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
    ["<leader>tg"] = { "<cmd> Telescope live_grep <CR>", "Live grep" },
    ["<leader>tb"] = { "<cmd> Telescope buffers <CR>", "Find buffers" },
    ["<leader>th"] = { "<cmd> Telescope help_tags <CR>", "Help page" },
    ["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "Find oldfiles" },
    ["<leader>fz"] = { "<cmd> Telescope current_buffer_fuzzy_find <CR>", "Find in current buffer" },

    -- git
    ["<leader>tc"] = { "<cmd> Telescope git_commits <CR>", "Git commits" },
    ["<leader>ts"] = { "<cmd> Telescope git_status <CR>", "Git status" },

    -- pick a hidden term
    ["<leader>tt"] = { "<cmd> Telescope terms <CR>", "Pick hidden term" },

    -- theme switcher
    ["<leader>tth"] = { "<cmd> Telescope themes <CR>", "Nvchad themes" },

    -- file browser
    ["<leader>fb"] = { "<cmd> Telescope file_browser path=%:p:h select_buffer=true <CR>", "File Browser" },

    ["<leader>tm"] = { "<cmd> Telescope marks <CR>", "telescope bookmarks" },
  },
}

M.fzf = {
  plugin = true,

  n = {
    -- buffers and files
    ["<c-P>"] = { "<cmd> FzfLua files <CR>", "Find files" },
    ["<leader>ff"] = { "<cmd> FzfLua files <CR>", "Find files" },
    ["<leader>ft"] = { "<cmd> FzfLua treesitter <CR>", "Current buffer treesitter symbols" },

    -- search
    ["<leader>rg"] = { "<cmd> FzfLua grep <CR>", "Grep" },
    ["<leader>gg"] = { "<cmd> FzfLua grep_cword <CR>", "Grep word under cursor" },
    ["<leader>gv"] = { "<cmd> FzfLua grep_visual <CR>", "Grep visual selection" },

    -- git
    ["<leader>gc"] = { "<cmd> FzfLua git_commits <CR>", "Git commit log" },
  },
}

M.conform = {
  plugin = true,

  n = {
    ["<leader>fm"] = { "<cmd> Format <CR>", "Format" },
  },
}

M.nvterm = {
  plugin = true,

  t = {
    -- toggle in terminal mode
    ["<A-i>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "Toggle floating term",
    },

    ["<A-h>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },
  },

  n = {
    -- toggle in normal mode
    ["<A-i>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "Toggle floating term",
    },

    ["<A-h>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },

    -- new
    ["<leader>h"] = {
      function()
        require("nvterm.terminal").new "horizontal"
      end,
      "New horizontal term",
    },

    ["<leader>v"] = {
      function()
        require("nvterm.terminal").new "vertical"
      end,
      "New vertical term",
    },
  },
}

M.whichkey = {
  plugin = true,

  n = {
    ["<leader>wK"] = {
      function()
        vim.cmd "WhichKey"
      end,
      "Which-key all keymaps",
    },
    ["<leader>wk"] = {
      function()
        local input = vim.fn.input "WhichKey: "
        vim.cmd("WhichKey " .. input)
      end,
      "Which-key query lookup",
    },
  },
}

M.blankline = {
  plugin = true,

  n = {
    ["<leader>cc"] = {
      function()
        local ok, start = require("indent_blankline.utils").get_current_context(
          vim.g.indent_blankline_context_patterns,
          vim.g.indent_blankline_use_treesitter_scope
        )

        if ok then
          vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { start, 0 })
          vim.cmd [[normal! _]]
        end
      end,

      "Jump to current context",
    },
  },
}

M.gitsigns = {
  plugin = true,

  n = {
    -- Navigation through hunks
    ["]c"] = {
      function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          require("gitsigns").next_hunk()
        end)
        return "<Ignore>"
      end,
      "Jump to next hunk",
      opts = { expr = true },
    },

    ["[c"] = {
      function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          require("gitsigns").prev_hunk()
        end)
        return "<Ignore>"
      end,
      "Jump to prev hunk",
      opts = { expr = true },
    },

    -- Actions
    ["<leader>rh"] = {
      function()
        require("gitsigns").reset_hunk()
      end,
      "Reset hunk",
    },

    ["<leader>ph"] = {
      function()
        require("gitsigns").preview_hunk()
      end,
      "Preview hunk",
    },

    ["<leader>gb"] = {
      function()
        package.loaded.gitsigns.blame_line()
      end,
      "Blame line",
    },

    ["<leader>td"] = {
      function()
        require("gitsigns").toggle_deleted()
      end,
      "Toggle deleted",
    },
  },
}

M.trouble = {
  plugin = true,

  n = {
    ["<leader>xx"] = {
      "<cmd>Trouble diagnostics toggle<cr>",
      "Diagnostics (Trouble)",
    },
    ["<leader>xX"] = {
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      "Buffer Diagnostics (Trouble)",
    },

    ["<leader>cs"] = {
      "<cmd>Trouble symbols toggle focus=false<cr>",
      "Symbols (Trouble)",
    },

    ["<leader>cl"] = {
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },

    ["<leader>xL"] = {
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },

    ["<leader>xQ"] = {
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  },
}

return M
