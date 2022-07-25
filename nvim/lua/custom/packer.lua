vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- Themes
    use 'NLKNguyen/papercolor-theme'
    -- use 'folke/tokyonight.nvim'
    -- use 'doums/darcula'
    -- use 'KeitaNakamura/neodark.vim'
    -- use 'sainnhe/sonokai'
    -- use 'joshdick/onedark.vim'
    -- use 'jaredgorski/SpaceCamp'
    -- use 'tomasiser/vim-code-dark'
    
    -- Git
    use 'airblade/vim-gitgutter'

    use 'preservim/nerdtree'
    
    use 'mfussenegger/nvim-dap'
    use 'rcarriga/nvim-dap-ui'

    use 'mhinz/vim-startify'

    use 'ms-jpq/coq_nvim'
    use 'ms-jpq/coq.artifacts'

    use 'vim-airline/vim-airline'

    use 'neovim/nvim-lspconfig'
    use 'sumneko/lua-language-server'

end)
