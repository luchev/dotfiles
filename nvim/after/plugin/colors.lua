vim.g.mapleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.updatetime = 50


vim.opt.errorbells = false

vim.g.PaperColor_Theme_Options = {
    theme={
        default={
            transparent_background=1
        }
    }
}
vim.opt.background = 'dark'
vim.cmd [[colorscheme PaperColor]]

