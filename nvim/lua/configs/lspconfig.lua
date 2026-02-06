-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require("lspconfig")

local servers = { "html", "cssls", "gopls", "ulsp" }
local nvlsp = require("nvchad.configs.lspconfig")

require("lspconfig.configs").ulsp = {
  default_config = {
    cmd = { "socat", "-", "tcp:localhost:27883,ignoreeof" },
    flags = {
      debounce_text_changes = 1000,
    },
    capabilities = vim.lsp.protocol.make_client_capabilities(),
    filetypes = { "go", "java" },
    root_dir = function(fname)
      local result = require("lspconfig.async").run_command({ "git", "rev-parse", "--show-toplevel" })
      if result and result[1] then
        return vim.trim(result[1])
      end
      return require("lspconfig.util").root_pattern(".git")(fname)
    end,
    single_file_support = false,
  },
}

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

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
