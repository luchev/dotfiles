require "nvchad.options"

local env = vim.env
local opt = vim.opt

-- Required so vim bypasses the go wrapper from Uber
env.USE_SYSTEM_GO = 1
-- Vim uses the go binary provided from bazel if it's set
env.PATH = env.VIM_PATH or env.PATH

opt.spell = true
opt.shell = "nu"
