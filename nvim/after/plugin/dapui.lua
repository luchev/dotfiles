local nnoremap = require("custom/keymap").nnoremap

require('dapui').setup()

-- Toggle dapui
nnoremap("gd", ":lua require('dapui').toggle()<CR>")
-- Evaluate currently hovered expression
nnoremap("ge", ":lua require('dapui').eval()<CR>")
