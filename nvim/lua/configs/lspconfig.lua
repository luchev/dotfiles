-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

-- Prevent signature help from auto-focusing; only focus on explicit <leader>ls
local sig_help_forced = false
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
  config = config or {}
  config.focus_id = "signature_help"
  if sig_help_forced then
    sig_help_forced = false
  else
    config.focusable = false
    config.focus = false
  end
  return vim.lsp.handlers.signature_help(err, result, ctx, config)
end

vim.keymap.set({ "n", "i" }, "<leader>ls", function()
  sig_help_forced = true
  vim.lsp.buf.signature_help()
end, { desc = "LSP signature help (focus)" })

local servers = { "html", "cssls", "gopls", "ulsp" }
local nvlsp = require("nvchad.configs.lspconfig")

-- Define custom ulsp server config
vim.lsp.config("ulsp", {
  cmd = { "socat", "-", "tcp:localhost:27883,ignoreeof" },
  flags = { debounce_text_changes = 1000 },
  filetypes = { "go", "java" },
  root_dir = function(fname)
    local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
    if result.code == 0 and result.stdout then
      return vim.trim(result.stdout)
    end
    return vim.fs.root(fname, { ".git" })
  end,
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  single_file_support = false,
})

-- lsps with default config
for _, lsp in ipairs(servers) do
  if lsp == "gopls" then
    -- Skip gopls here, configure it separately below
    goto continue
  end

  vim.lsp.config(lsp, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })

  ::continue::
end

-- Configure gopls with custom settings
vim.lsp.config("gopls", {
  on_attach = nvlsp.on_attach,
  cmd = { "gopls", "-remote=auto" },
  filetypes = { "go", "gomod", "gotmpl", "gowork" },
  init_options = {
    staticcheck = true,
  },
  capabilities = nvlsp.capabilities,
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
})

-- Enable all configured LSP servers
for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end
