return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "mhinz/vim-startify",
    lazy = false,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = function()
      return require "configs.gitsigns"
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "git")
      require("gitsigns").setup(opts)
    end,
  },

  {
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
    -- git branch viewer
    "rbong/vim-flog",
    cmd = { "Flog", "Flogsplit", "Floggit" },
    dependencies = {
      "tpope/vim-fugitive",
    },
  },

  {
    "tanvirtin/vgit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = { "VGit" },
    config = function()
      require("vgit").setup()
    end,
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffViewFileHistory" },
    config = function()
      require("diffview").setup()
    end,
  },

  -- lsp stuff
  {
    "neovim/nvim-lspconfig",
    event = "User FilePost",
    config = function()
      require "configs.lspconfig"
    end,
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
  },

  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
    opts = function()
      return require "configs.mason"
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "mason")
      require("mason").setup(opts)

      -- custom cmd to install all mason binaries listed
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        if opts.ensure_installed and #opts.ensure_installed > 0 then
          vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
        end
      end, {})

      vim.g.mason_binaries_list = opts.ensure_installed
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
      return require "configs.treesitter"
    end,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-refactor",
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    cmd = { "TSContextEnable", "TSContextToggle" },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
  },

  {
    "nvimdev/lspsaga.nvim",
    lazy = true,
    event = "LspAttach",
    config = function()
      require("lspsaga").setup {
        lightbulb = {
          -- turn off code action light bulb around the line
          enabled = false,
        },
      }
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },

  {
    "mfussenegger/nvim-lint",
    init = function()
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
    opts = function()
      return require "configs.nvimlint"
    end,
    config = function(_, opts)
      local lint = require "lint"
      lint.linters_by_ft = opts.linters_by_ft
      lint.linters = opts.linters
    end,
    event = {
      "BufWritePost", -- on save
      -- "InsertLeave" -- on leaving insert mode
    },
  },

  {
    "stevearc/conform.nvim",
    cmd = { "Format" },
    opts = function()
      return require "configs.conform"
    end,
    config = function(_, opts)
      require("conform").setup(opts)

      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        require("conform").format { async = true, lsp_format = "fallback", range = range }
      end, { range = true })
    end,
  },

  -- {
  --   "ray-x/go.nvim",
  --   dependencies = { -- optional packages
  --     "ray-x/guihua.lua",
  --     "neovim/nvim-lspconfig",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   config = function()
  --     require("go").setup()
  --   end,
  --   event = { "CmdlineEnter" },
  --   ft = { "go", "gomod" },
  --   build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  -- },

  {
    "mfussenegger/nvim-dap",
  },
  {
    "rcarriga/nvim-dap-ui",
    event = "LspAttach",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    opts = {},
    config = function()
      local map = vim.keymap.set
      local dap = require "dap"
      local dapui = require "dapui"
      local widgets = require "dap.ui.widgets"
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

      map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP Toggle breakpoint" })
      map("n", "<leader>dt", function()
        sidebar.toggle()
      end, { desc = "DAP Toggle sidebar" })
    end,
  },

  -- load luasnips + cmp related in insert mode only
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    opts = function()
      return require "configs.cmp"
    end,
    config = function(_, opts)
      require("cmp").setup(opts)
    end,
    dependencies = {
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
  },

  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function()
      require("claude-code").setup({
        shell = {
          separator = ';',        -- Command separator used in shell commands
          pushd_cmd = 'enter',     -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
          popd_cmd = 'exit',       -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
        },
      })
    end,
    cmd = { "ClaudeCode" },
  },

  {
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

  -- file managing , picker etc
  {
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
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
      },
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
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },

  {
    "nvim-telescope/telescope-dap.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },

  {
    -- Search files by recently opened
    "nvim-telescope/telescope-frecency.nvim",
    version = "*",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config= function()
      require("telescope-frecency").setup{
        db_safe_mode =false,
        matcher = "fuzzy",

      }
    end,
  },

  {
    "benfowler/telescope-luasnip.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    "HPRIOR/telescope-gpt",
    dependencies = { "nvim-telescope/telescope.nvim", "jackMort/ChatGPT.nvim" },
  },

  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua",
    keys = { "<c-P>" },
    config = function()
      require("fzf-lua").setup {
        defaults = {
          -- Do not run git status for fzf commands
          git_icons = false,
        },
      }
    end,
  },

  -- Only load whichkey after all the gui
  {
    "folke/which-key.nvim",
    keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
    cmd = "WhichKey",
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "whichkey")
      -- require("which-key").setup(opts)
    end,
  },

  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
  },

  -- code stuff
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = function()
      return require "configs.copilot"
    end,
    config = function(_, opts)
      require("copilot").setup(opts)
    end,
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      highlight_headers = false,
      separator = "---",
      error_header = "> [!ERROR] Error",
    },
    cmd = { "CopilotChat" },
    config = function(_, opts)
      require("CopilotChat").setup(opts)
    end,
  },

  {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
      local home = vim.fn.expand "$HOME"
      require("chatgpt").setup {
        api_key_cmd = "sh " .. home .. "/.gpt-key.sh",
        keymaps = {
          submit = "<C-s>",
        },
      }
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "folke/trouble.nvim", -- optional
      "nvim-telescope/telescope.nvim",
    },
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {}
    end,
  },

  {
    "mg979/vim-visual-multi",
  },

  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },

  {
    "chrisbra/NrrwRgn",
    keys = {
      { "<leader>nr", mode = "v", desc = "Narrow Region from selection" },
    },
  },

  {
    -- Dim inactive windows
    "tadaa/vimade",
    event = "VeryLazy",
  },

  {
    --
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "copilot-chat" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ---@module 'render-markdown'
    opts = {
      file_types = { "markdown", "copilot-chat" },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
    end,
  },

  {
    -- Notifications in the top-right corner
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = function()
      return require "configs.noice"
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function(_, opts)
      require("noice").setup(opts)
    end,
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = function()
      return require "configs.flash"
    end,
  },

  {
    -- Notifications in the lower right corner
    "j-hui/fidget.nvim",
    opts = {},
  },

  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
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
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/vaults/personal",
        },
        {
          name = "work",
          path = "~/vaults/work",
        },
      },
    },
  },

  {
    "AckslD/nvim-neoclip.lua",
    dependencies = {
      { "nvim-telescope/telescope.nvim" },
    },
    config = function()
      require("neoclip").setup()
    end,
  },

  {
    "rhysd/vim-grammarous",
    cmd = "GrammarousCheck",
    config = function()
      vim.g["grammarous#jar_url"] = "https://www.languagetool.org/download/archive/LanguageTool-5.9.zip"
    end,
  },

  {
    -- Better quickfix window
    "kevinhwang91/nvim-bqf",
    event = { "BufRead", "BufNew" },
  },

  {
    -- Funny snow effect
    "marcussimonsen/let-it-snow.nvim",
    cmd = "LetItSnow",
    config = function()
      require("let-it-snow").setup {
        delay = 500,
      }
    end,
  },

  {
    "nanotee/zoxide.vim",
    cmd = "Z",
  },

}
