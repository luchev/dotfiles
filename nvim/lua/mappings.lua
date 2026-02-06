require("nvchad.mappings")

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

map("i", "jk", "<ESC>", { desc = "general exit insert mode " })
map("i", "kj", "<ESC>", { desc = "general exit insert mode " })

map("v", "<leader>ca", function()
  vim.lsp.buf.code_action()
end, { desc = "LSP code action" })
map("n", "gD", function()
  vim.lsp.buf.declaration()
end, { desc = "LSP declaration" })
map("n", "gd", function()
  vim.lsp.buf.definition()
end, { desc = "LSP definition" })
map("n", "K", function()
  vim.lsp.buf.hover()
end, { desc = "LSP hover" })
map("n", "gi", function()
  vim.lsp.buf.implementation()
end, { desc = "LSP implementation" })
map("n", "<leader>ls", function()
  vim.lsp.buf.signature_help()
end, { desc = "LSP signature help" })
map("n", "<leader>D", function()
  vim.lsp.buf.type_definition()
end, { desc = "LSP definition type" })
map("n", "<leader>ra", function()
  require("nvchad.renamer").open()
end, { desc = "LSP rename" })
map("n", "<leader>gr", function()
  vim.lsp.buf.references()
end, { desc = "LSP references" })
map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, { desc = "LSP rename" })
map("n", "<leader>lf", function()
  vim.diagnostic.open_float { border = "rounded" }
end, { desc = "Floating diagnostic" })
map("n", "[d", function()
  vim.diagnostic.goto_prev { float = { border = "rounded" } }
end, { desc = "Goto prev" })
map("n", "]d", function()
  vim.diagnostic.goto_next { float = { border = "rounded" } }
end, { desc = "Goto next" })
map("n", "[q", function()
  vim.diagnostic.goto_prev { severity = { min = vim.diagnostic.severity.WARN }, float = { border = "rounded" } }
end, { desc = "Goto prev issue (error/warning)" })
map("n", "]q", function()
  vim.diagnostic.goto_next { severity = { min = vim.diagnostic.severity.WARN }, float = { border = "rounded" } }
end, { desc = "Goto next issue (error/warning)" })
map("n", "<leader>q", function()
  vim.diagnostic.setloclist()
end, { desc = "Diagnostic setloclist" })
map("n", "<leader>wa", function()
  vim.lsp.buf.add_workspace_folder()
end, { desc = "Add workspace folder" })
map("n", "<leader>wr", function()
  vim.lsp.buf.remove_workspace_folder()
end, { desc = "Remove workspace folder" })
map("n", "<leader>wl", function()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = "List workspace folders" })
map("n", "<leader>.", function()
  vim.lsp.buf.code_action()
end, { desc = "" })

map("n", "<leader>tf", "<cmd>Telescope frecency<CR>", { desc = "telescope find files" })
map("n", "<leader>tw", "<cmd>Telescope live_grep_args<CR>", { desc = "telescope live grep (args)" })
map("n", "<leader>tu", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>th", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>tm", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>to", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>tz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>tc", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>tg", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>ts", "<cmd>Telescope luasnip<CR>", { desc = "telescope luasnip" })
map("n", "<leader>tt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })
map("n", "<leader>ty", "<cmd>Telescope neoclip<CR>", { desc = "telescope neoclip yank history" })
map(
  "n",
  "<leader>tb",
  "<cmd>Telescope file_browser path=%:p:h select_buffer=true <CR>",
  { desc = "telescope file browser" }
)

map("n", "<leader>ff", "<cmd> FzfLua files <CR>", { desc = "Fzf find files" })
map("n", "<c-P>", "<cmd> FzfLua files <CR>", { desc = "Fzf find files" })
map("n", "<leader>ft", "<cmd> FzfLua treesitter <CR>", { desc = "Fzf treesitter symbols" })
map("n", "<leader>fg", "<cmd> FzfLua grep <CR>", { desc = "Fzf grep" })
map("n", "<leader>fw", "<cmd> FzfLua grep_cword <CR>", { desc = "Fzf grep word under cursor" })
map("n", "<leader>fl", "<cmd> FzfLua git_commits <CR>", { desc = "Fzf git log" })
map("v", "<leader>fv", "<cmd> FzfLua grep_visual <CR>", { desc = "Fzf grep visual selection" })

map("n", "<leader>fm", "<cmd> Format <CR>", { desc = "conform Format" })

map("n", "<leader>xx", "<cmd> TroubleToggle<CR>", { desc = "trouble toggle" })
map("n", "<leader>xX", "<cmd> TroubleToggle lsp_document_diagnostics<CR>", { desc = "trouble toggle diagnostics" })
map("n", "<leader>cs", "<cmd> TroubleToggle lsp_workspace_symbols<CR>", { desc = "trouble toggle symbols" })
map("n", "<leader>cl", "<cmd> TroubleToggle lsp_references<CR>", { desc = "trouble toggle lsp references" })
map("n", "<leader>xL", "<cmd> TroubleToggle loclist<CR>", { desc = "trouble toggle loclist" })
map("n", "<leader>xQ", "<cmd> TroubleToggle quickfix<CR>", { desc = "trouble toggle quickfix" })

map("n", "<leader>ccb", function()
  local input = vim.fn.input "Chat with buffer: "
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end, { desc = "Copilot chat with buffer" })

map("v", "<leader>cc", function()
  local input = vim.fn.input "Chat with selection: "
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").visual })
  end
end, { desc = "Copilot chat with visual selection" })

map("n", "<leader>ccp", function()
  local actions = require("CopilotChat.actions")
  require("CopilotChat.integrations.telescope").pick(actions.prompt_actions())
end, { desc = "Copilot prompt actions" })

map("n", "<leader>cca", function()
  local input = vim.fn.input "Chat with all files: "
  if input ~= "" then
    require("CopilotChat").ask(input, { context = { "buffers", "files:full", "register:+" } })
  end
end, { desc = "Copilot ask about all files" })

map("n", "s", function()
  require("flash").jump {
    pattern = ".", -- initialize pattern with any char
    search = {
      mode = function(pattern)
        -- remove leading dot
        if pattern:sub(1, 1) == "." then
          pattern = pattern:sub(2)
        end
        -- return word pattern and proper skip pattern
        return ([[\<%s\w*\>]]):format(pattern), ([[\<%s]]):format(pattern)
      end,
    },
    -- select the range
    jump = { pos = "range" },
  }
end, { desc = "Flash search" })
map("n", "S", function()
  require("flash").treesitter()
end, { desc = "Flash Treesitter" })

map("n", "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "NeoTree toggle" })
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "NeoTree toggle" })

-- Toggle Claude Code with <C-g> in any mode
map({"n", "v", "i", "c", "t", "o"}, "<C-g>", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })

