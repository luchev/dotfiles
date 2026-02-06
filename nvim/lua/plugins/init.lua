return {
  {
    -- Auto-formatting with support for multiple formatters
    "stevearc/conform.nvim",
    cmd = { "Format" },
    opts = function()
      return require("configs.conform")
    end,
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        conform.format { async = true, lsp_format = "fallback", range = range }
      end, { range = true })
    end,
  },

  {
    -- Native LSP configuration for language servers
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      require("configs.lspconfig")
    end,
  },

  {
    -- Package manager for LSP servers, DAP servers, linters, and formatters
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
    opts = function()
      return require("configs.mason")
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "mason")
      require("mason").setup(opts)
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        if opts.ensure_installed and #opts.ensure_installed > 0 then
          vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
        end
      end, {})
      vim.g.mason_binaries_list = opts.ensure_installed
    end,
  },

  {
    -- Bridge between mason.nvim and nvim-lspconfig
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
  },

  {
    -- Enhanced LSP UI with better code actions, hover, and diagnostics
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup {
        lightbulb = { enabled = false },
      }
    end,
    keys = {
      { "<leader>lf", "<cmd>Lspsaga finder<cr>", desc = "LSP finder" },
      { "<leader>ld", "<cmd>Lspsaga goto_definition<cr>", desc = "Go to definition" },
      { "<leader>lD", "<cmd>Lspsaga peek_definition<cr>", desc = "Peek definition" },
      { "<leader>lt", "<cmd>Lspsaga goto_type_definition<cr>", desc = "Go to type definition" },
      { "<leader>lT", "<cmd>Lspsaga peek_type_definition<cr>", desc = "Peek type definition" },
      { "<leader>lh", "<cmd>Lspsaga hover_doc<cr>", desc = "Hover documentation" },
      { "<leader>la", "<cmd>Lspsaga code_action<cr>", mode = { "n", "v" }, desc = "Code action" },
      { "<leader>lr", "<cmd>Lspsaga rename<cr>", desc = "Rename" },
      { "<leader>lo", "<cmd>Lspsaga outline<cr>", desc = "Outline" },
      { "<leader>l[", "<cmd>Lspsaga diagnostic_jump_prev<cr>", desc = "Previous diagnostic" },
      { "<leader>l]", "<cmd>Lspsaga diagnostic_jump_next<cr>", desc = "Next diagnostic" },
      { "<leader>ls", "<cmd>Lspsaga show_line_diagnostics<cr>", desc = "Line diagnostics" },
    },
  },

  {
    -- Asynchronous linter integration
    "mfussenegger/nvim-lint",
    event = { "BufWritePost" },
    opts = function()
      return require("configs.nvimlint")
    end,
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft
      lint.linters = opts.linters
      vim.api.nvim_create_user_command("Lint", function()
        lint.try_lint()
      end, {})
    end,
    init = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },

  {
    -- Syntax highlighting, incremental parsing, and code understanding
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-refactor",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function()
      return require("configs.treesitter")
    end,
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.asciidoc = {
        install_info = {
          url = "https://github.com/cathaysia/tree-sitter-asciidoc.git",
          files = { "tree-sitter-asciidoc/src/parser.c", "tree-sitter-asciidoc/src/scanner.c" },
          branch = "master",
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
      }
      parser_config.asciidoc_inline = {
        install_info = {
          url = "https://github.com/cathaysia/tree-sitter-asciidoc.git",
          files = { "tree-sitter-asciidoc_inline/src/parser.c", "tree-sitter-asciidoc_inline/src/scanner.c" },
          branch = "master",
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
      }
    end,
  },

  {
    -- Show current code context at the top of the window
    "nvim-treesitter/nvim-treesitter-context",
    cmd = { "TSContextEnable", "TSContextToggle" },
  },

  {
    -- Treesitter parser for AsciiDoc files
    "cathaysia/tree-sitter-asciidoc",
  },

  {
    -- Git signs in the gutter and inline blame
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require("configs.gitsigns")
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "git")
      require("gitsigns").setup(opts)
    end,
  },

  {
    -- Git wrapper with commands like :Git, :Gdiffsplit
    "tpope/vim-fugitive",
    cmd = {
      "G",
      "Git",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Gedit",
      "Gsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "Glgrep",
      "Gmove",
      "Gdelete",
      "Gremove",
      "Gbrowse",
    },
  },

  {
    -- Git branch viewer and explorer
    "rbong/vim-flog",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = { "tpope/vim-fugitive" },
  },

  {
    -- Visual git interface with hunks and blame
    "tanvirtin/vgit.nvim",
    cmd = { "VGit" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("vgit").setup()
    end,
  },

  {
    -- Git diff viewer and merge tool
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffViewFileHistory" },
    config = function()
      require("diffview").setup()
    end,
  },

  -- Debugging
  {
    -- Debug Adapter Protocol client implementation
    "mfussenegger/nvim-dap",
  },

  {
    -- UI for nvim-dap with variable inspection and REPL
    "rcarriga/nvim-dap-ui",
    event = "LspAttach",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local widgets = require("dap.ui.widgets")
      local sidebar = widgets.sidebar(widgets.scopes)

      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dt", function()
        sidebar.toggle()
      end, { desc = "DAP Toggle sidebar" })
    end,
  },

  {
    -- Autocompletion engine with LSP, snippets, and buffer support
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-cmdline",
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
    opts = function()
      return require("configs.cmp")
    end,
    config = function(_, opts)
      local cmp = require("cmp")
      cmp.setup(opts)
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          {
            name = "cmdline",
            option = { ignore_cmds = { "Man", "!" } },
          },
        }),
      })
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
    end,
  },

  {
    -- Claude Code integration for AI pair programming
    "coder/claudecode.nvim",
    cmd = { "ClaudeCode" },
    dependencies = { "folke/snacks.nvim" },
    config = true,
    opts = function()
      local has_aifx = vim.fn.executable "aifx" == 1
      return {
        terminal_cmd = has_aifx and "aifx agent run claude" or nil,
        terminal = {
          split_side = "right",
          split_width_percentage = 0.5,
        },
      }
    end,
    keys = {
      { "<leader>a", nil, desc = "AI/Claude Code" },
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      {
        "<leader>as",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "oil", "minifiles" },
      },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },

  {
    -- GitHub Copilot integration for AI code suggestions
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = function()
      return require("configs.copilot")
    end,
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },

  {
    -- Chat interface for GitHub Copilot
    "CopilotC-Nvim/CopilotChat.nvim",
    cmd = { "CopilotChat" },
    build = "make tiktoken",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    opts = {
      highlight_headers = false,
      separator = "---",
      error_header = "> [!ERROR] Error",
    },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
  },

  -- File Navigation
  {
    -- Start screen with recent files and sessions
    "mhinz/vim-startify",
    lazy = false,
  },

  {
    -- File explorer tree with git integration
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    opts = function()
      return require "configs.nvimtree"
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "nvimtree")
      require("nvim-tree").setup(opts)
    end,
  },

  {
    -- Zoxide integration for smart directory jumping
    "nanotee/zoxide.vim",
    cmd = "Z",
  },

  {
    -- Fuzzy finder for files, buffers, LSP symbols, and more
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-telescope/telescope-dap.nvim",
      "nvim-telescope/telescope-frecency.nvim",
      "benfowler/telescope-luasnip.nvim",
      "HPRIOR/telescope-gpt",
    },
    opts = function(_, opts)
      local function flash(prompt_bufnr)
        require("flash").jump {
          pattern = "^",
          label = { after = { 0, 0 } },
          search = {
            mode = "search",
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
              end,
            },
          },
          action = function(match)
            local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        }
      end
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        mappings = {
          n = { s = flash },
          i = { ["<c-s>"] = flash },
        },
      })
    end,
  },

  {
    -- Frecency-based file picker that learns from usage
    "nvim-telescope/telescope-frecency.nvim",
    version = "*",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope-frecency").setup {
        db_safe_mode = false,
        matcher = "fuzzy",
      }
    end,
  },

  {
    -- Fast fuzzy finder using fzf algorithm
    "ibhagwan/fzf-lua",
    cmd = { "FzfLua", "F" },
    keys = { "<c-P>" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
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
    end,
  },

  {
    -- Displays keybindings in a popup
    "folke/which-key.nvim",
    cmd = "WhichKey",
    keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "whichkey")
    end,
  },

  {
    -- Pretty list for diagnostics, references, and quickfix
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
  },

  {
    -- Highly experimental UI for messages, cmdline, and popupmenu
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = function()
      return require("configs.noice")
    end,
    config = function(_, opts)
      require("noice").setup(opts)
    end,
  },

  {
    -- LSP progress notifications in the corner
    "j-hui/fidget.nvim",
    opts = {},
  },

  {
    -- Jump to any location with minimal keystrokes
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = function()
      return require("configs.flash")
    end,
  },

  {
    -- Indent guides with scope indicators
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufReadPre",
    opts = {
      indent = { char = "│" },
      scope = { enabled = false },
    },
  },

  {
    -- Highlight other uses of the word under the cursor
    "RRethy/vim-illuminate",
    event = "BufReadPost",
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = { providers = { "lsp" } },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },

  {
    -- Dim inactive windows for better focus
    "tadaa/vimade",
    event = "VeryLazy",
  },

  {
    -- Render markdown with treesitter in buffers
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "copilot-chat" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      file_types = { "markdown", "copilot-chat" },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },

  {
    -- Code outline sidebar with symbols from LSP and treesitter
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialClose", "AerialNext", "AerialPrev" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Aerial toggle (outline)" },
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "asciidoc", "man" },
      layout = {
        max_width = { 40, 0.2 },
        width = nil,
        min_width = 30,
        default_direction = "prefer_right",
        resize_to_content = true,
      },
      attach_mode = "global",
      close_on_select = true,
      show_guides = true,
      highlight_mode = "split_width",
      highlight_on_hover = true,
      highlight_on_jump = 300,
      autojump = true,
      post_jump_cmd = "normal! zz",
      keymaps = {
        ["?"] = "actions.show_help",
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.jump",
        ["<2-LeftMouse>"] = "actions.jump",
        ["<C-v>"] = "actions.jump_vsplit",
        ["<C-s>"] = "actions.jump_split",
        ["p"] = "actions.scroll",
        ["<C-j>"] = "actions.down_and_scroll",
        ["<C-k>"] = "actions.up_and_scroll",
        ["{"] = "actions.prev",
        ["}"] = "actions.next",
        ["[["] = "actions.prev_up",
        ["]]"] = "actions.next_up",
        ["q"] = "actions.close",
        ["o"] = "actions.tree_toggle",
        ["za"] = "actions.tree_toggle",
        ["O"] = "actions.tree_toggle_recursive",
        ["zA"] = "actions.tree_toggle_recursive",
        ["l"] = "actions.tree_open",
        ["zo"] = "actions.tree_open",
        ["L"] = "actions.tree_open_recursive",
        ["zO"] = "actions.tree_open_recursive",
        ["h"] = "actions.tree_close",
        ["zc"] = "actions.tree_close",
        ["H"] = "actions.tree_close_recursive",
        ["zC"] = "actions.tree_close_recursive",
        ["zr"] = "actions.tree_increase_fold_level",
        ["zR"] = "actions.tree_open_all",
        ["zm"] = "actions.tree_decrease_fold_level",
        ["zM"] = "actions.tree_close_all",
        ["zx"] = "actions.tree_sync_folds",
        ["zX"] = "actions.tree_sync_folds",
      },
      lsp = {
        update_when_errors = true,
        update_delay = 300,
      },
      treesitter = {
        update_delay = 300,
      },
      nerd_font = "auto",
    },
  },

  {
    -- Smart commenting with treesitter integration
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle current line" },
      { "gc", mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc", mode = "x", desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n", desc = "Comment toggle current block" },
      { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    },
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },

  {
    -- Collection of minimal plugins: surround, pairs, move, indentscope, ai
    "echasnovski/mini.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("mini.surround").setup()
      require("mini.ai").setup()
      require("mini.pairs").setup()
      require("mini.bufremove").setup()
      require("mini.indentscope").setup {
        symbol = "│",
        options = { try_as_border = true },
        draw = {
          animation = function()
            return 0
          end,
        },
      }
      require("mini.move").setup()
    end,
  },

  {
    -- Multiple cursors and selections
    "mg979/vim-visual-multi",
  },

  {
    -- Narrow region editing in a separate buffer
    "chrisbra/NrrwRgn",
    keys = {
      { "<leader>nr", mode = "v", desc = "Narrow Region from selection" },
    },
  },

  -- Utilities
  {
    -- Highlight and navigate TODO, FIXME, and other comments
    "folke/todo-comments.nvim",
    event = "BufReadPre",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
    },
  },

  {
    -- Visualize undo history as a tree
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },

  {
    -- Mark visualization and navigation
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    -- Peek at register contents before pasting
    "tversteeg/registers.nvim",
    cmd = "Registers",
    config = true,
    keys = {
      { '"', mode = { "n", "v" } },
      { "<C-R>", mode = "i" },
    },
    name = "registers",
  },

  {
    -- Clipboard history manager with telescope integration
    "AckslD/nvim-neoclip.lua",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("neoclip").setup()
    end,
  },

  {
    -- Grammar checker using LanguageTool
    "rhysd/vim-grammarous",
    cmd = "GrammarousCheck",
    config = function()
      vim.g["grammarous#jar_url"] = "https://www.languagetool.org/download/archive/LanguageTool-5.9.zip"
    end,
  },

  {
    -- Better quickfix window with preview and filtering
    "kevinhwang91/nvim-bqf",
    event = { "BufRead", "BufNew" },
  },

  {
    -- Snowfall animation for fun
    "marcussimonsen/let-it-snow.nvim",
    cmd = "LetItSnow",
    config = function()
      require("let-it-snow").setup { delay = 500 }
    end,
  },

  {
    -- AsciiDoc syntax and filetype support
    "mjakl/vim-asciidoc",
    event = "BufRead */adoc/*.adoc",
  },
}
