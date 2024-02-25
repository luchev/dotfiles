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
    -- use 'OmniSharp/omnisharp-vim'
    -- use '907th/vim-auto-save'
    -- use 'NLKNguyen/papercolor-theme'
    -- use 'ctrlpvim/ctrlp.vim'
    -- use 'vim-airline/vim-airline'
    -- use 'ervandew/supertab'
    -- use 'mbbill/undotree'
    -- use 'preservim/nerdtree'
    -- use 'mhinz/vim-startify'
    -- use 'tpope/vim-commentary'
    -- use 'tpope/vim-fugitive'
    -- use 'tpope/vim-surround'
    -- use 'rbong/vim-flog'
    -- use 'mfussenegger/nvim-dap'
    -- use 'rcarriga/nvim-dap-ui'

    -- use 'neovim/nvim-lspconfig'
    -- use 'sumneko/lua-language-server'
    -- use 'vim-syntastic/syntastic'
    -- use 'dense-analysis/ale'
    -- use 'vim-autoformat/vim-autoformat'

    use({
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup()
        end
    })
    use("hrsh7th/nvim-cmp")
    use({
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-vsnip",
        after = { "hrsh7th/nvim-cmp" },
        requires = { "hrsh7th/nvim-cmp" },
    })

    -- Snippet engine
    use('hrsh7th/vim-vsnip')
    -- Adds extra functionality over rust analyzer
    use("simrat39/rust-tools.nvim")

    -- Optional
    use("nvim-lua/popup.nvim")
    use("nvim-lua/plenary.nvim")
    use("nvim-telescope/telescope.nvim")
end)

