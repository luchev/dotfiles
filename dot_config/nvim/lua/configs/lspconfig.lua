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

local servers = { "html", "cssls", "gopls", "ulsp", "harper_ls" }
local nvlsp = require("nvchad.configs.lspconfig")

-- Define custom ulsp server config
vim.lsp.config("ulsp", {
  cmd = { "socat", "-", "tcp:localhost:27883,ignoreeof" },
  flags = { debounce_text_changes = 1000 },
  filetypes = { "go", "java" },
  root_dir = function(bufnr, cb)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local bufdir = vim.fn.fnamemodify(fname, ":h")
    -- Use git common dir to get main repo root (works in both main repo and worktrees)
    local result = vim.system({ "git", "rev-parse", "--git-common-dir" }, { text = true, cwd = bufdir }):wait()
    if result.code == 0 and result.stdout then
      local git_common_dir = vim.trim(result.stdout)
      -- git-common-dir is either ".git" (main repo) or an absolute path (worktree)
      if git_common_dir == ".git" then
        cb(vim.fs.root(fname, { ".git" }))
      else
        -- In a worktree: git-common-dir is /main/repo/.git, parent is main repo root
        cb(vim.fn.fnamemodify(git_common_dir, ":h"))
      end
    else
      cb(vim.fs.root(fname, { ".git" }))
    end
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
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gotmpl", "gowork" },
  root_dir = function(bufnr, cb)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { "go.work", "go.mod", ".git" })
    cb(root)
  end,
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

-- LspRestart for native vim.lsp.enable-managed servers
vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    client:stop()
  end
  vim.defer_fn(function() vim.cmd("edit") end, 500)
end, {})

-- LspStatus: show active clients for current buffer
vim.api.nvim_create_user_command("LspStatus", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP clients attached to this buffer", vim.log.levels.WARN)
    return
  end
  local lines = {}
  for _, client in ipairs(clients) do
    local status = client.initialized and "initialized" or "initializing"
    local caps = client.server_capabilities or {}
    local has_def = caps.definitionProvider and "yes" or "no"
    local has_ref = caps.referencesProvider and "yes" or "no"
    table.insert(lines, string.format(
      "[%d] %s  status=%s  definition=%s  references=%s  root=%s",
      client.id, client.name, status, has_def, has_ref, client.root_dir or "none"
    ))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {})
