vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- use 'KeitaNakamura/neodark.vim'
    -- use 'doums/darcula'
    -- use 'folke/tokyonight.nvim'
    -- use 'jaredgorski/SpaceCamp'
    -- use 'joshdick/onedark.vim'
    -- use 'sainnhe/sonokai'
    -- use 'tomasiser/vim-code-dark'
    use 'NLKNguyen/papercolor-theme'
    use 'ctrlpvim/ctrlp.vim'
    use 'dense-analysis/ale'
    use 'ervandew/supertab'
    use 'mfussenegger/nvim-dap'
    use 'mhinz/vim-startify'
    use 'ms-jpq/coq.artifacts'
    use 'ms-jpq/coq_nvim'
    use 'neovim/nvim-lspconfig'
    use 'preservim/nerdtree'
    use 'rcarriga/nvim-dap-ui'
    use 'sumneko/lua-language-server'
    use 'tpope/vim-commentary'
    use 'tpope/vim-fugitive'
    use 'vim-airline/vim-airline'
    use 'vim-syntastic/syntastic'
    use 'tpope/vim-surround'
    use '907th/vim-auto-save'

end)