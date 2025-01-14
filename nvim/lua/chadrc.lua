-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(
--
local stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local separators = {
  default = { left = "", right = "" },
  round = { left = "", right = "" },
  block = { left = "█", right = "█" },
  arrow = { left = "", right = "" },
  general = "",
  -- 
}

-- local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥", "" }

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "doomchad", -- tokyodark, doomchad, tokyonight, tomorrow_night
}

M.term = {
  winopts = { number = false, relativenumber = false },
  sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
  float = {
    relative = "editor",
    row = 0.1,
    col = 0.1,
    width = 0.8,
    height = 0.8,
    border = "single",
  },
}

M.ui = {
  statusline = {
    separator_style = "default",
    order = {
      "mode",
      "path",
      "git",
      "%=",
      "lsp_msg",
      "%=",
      "diagnostics",
      "lsp",
      "position",
      "position_percent",
      "cwd",
    },
    modules = {
      path = function()
        local icon = "󰈚"
        local path = vim.api.nvim_buf_get_name(stbufnr())
        local name = (path == "" and "Empty") or path:match "([^/\\]+)[/\\]*$"

        if name ~= "Empty" then
          local devicons_present, devicons = pcall(require, "nvim-web-devicons")
          if devicons_present then
            local ft_icon = devicons.get_icon(name)
            icon = (ft_icon ~= nil and ft_icon) or icon
          end
        end
        return "%#St_file# " .. icon .. " %F" .. "%#St_file_sep#" .. separators.default.right
      end,
      position = function()
        return "%#St_pos_sep#" .. "" .. "%#St_pos_icon#" .. "" .. "%#St_pos_sep#" .. "█ %l:%c "
      end,
      position_percent = function()
        return "%#St_pos_sep#" .. "" .. "%#St_pos_icon#" .. "" .. "%#St_pos_sep#" .. "█ %p "
      end,
    },
  },
}

return M
