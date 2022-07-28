local nnoremap = require("custom/keymap").nnoremap

-- Toggle NerdTree on/off with Ctrl+t
nnoremap("<C-t>", ":NERDTreeToggle<CR>")
-- Toggle NerdTree and go to current file
nnoremap("<C-f>", ":NERDTreeFind<CR>")
