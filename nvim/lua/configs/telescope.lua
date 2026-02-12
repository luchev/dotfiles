return function(_, opts)
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
      mappings = {
        n = { s = flash },
        i = { ["<c-s>"] = flash },
      },
    },
    extensions_list = { "themes", "terms", "file_browser", "dap", "frecency", "luasnip", "gpt", "live_grep_args" },
  }

  return vim.tbl_deep_extend("force", opts or {}, options)
end
