require "nvchad.options"

local env = vim.env
local opt = vim.opt

env.USE_SYSTEM_GO = 1

opt.spell = true
opt.shell = "nu"
