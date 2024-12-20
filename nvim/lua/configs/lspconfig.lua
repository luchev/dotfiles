-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

local servers = { "html", "cssls", "gopls" }
local nvlsp = require "nvchad.configs.lspconfig"

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- configuring single server, example: typescript

require("lspconfig").gopls.setup {
  on_attach = nvlsp.on_attach,
  cmd = { "gopls", "-remote=auto" },
  filetypes = { "go", "gomod", "gotmpl", "gowork" },
  flags = {
    debounce_text_changes = 1000,
  },
  init_options = {
    staticcheck = true,
  },
  single_file_support = true,
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
    },
  },
}
