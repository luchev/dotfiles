local nnoremap = require("custom/keymap").nnoremap

-- Toggle UndoTree on/off
nnoremap("<C-s>", ":UndotreeToggle<CR>:UndotreeFocus<CR>")
