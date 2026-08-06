require("nvchad.options")

local env = vim.env
local opt = vim.opt

-- OSC 52 clipboard: yanks reach the local clipboard over SSH + Zellij.
-- Zellij passes OSC 52 through to the outer terminal (WezTerm) by default.
-- Paste from external clipboard via terminal paste (Cmd+V); nvim-internal
-- paste (p/P) works within the same Zellij session via Zellij's clipboard.
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
opt.clipboard = "unnamedplus"

-- Optional machine-local overrides (kept outside this repo)
local local_cfg = vim.fn.expand("~/.config/nvim-local.lua")
if vim.loop.fs_stat(local_cfg) then dofile(local_cfg) end
-- Overwrite PATH with VIM_PATH if set
env.PATH = env.VIM_PATH or env.PATH

opt.spell = true
opt.shell = "nu"
