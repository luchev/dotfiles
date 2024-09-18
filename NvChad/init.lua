require "core"

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]

if custom_init_path then
  dofile(custom_init_path)
end

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)
require "plugins"

function goFormatAndImports(wait_ms)
 
    -- Prefer `format` if available because `formatting_sync` has been deprecated as of nvim v0.8.0.
    if vim.lsp.buf.format == nil then
        vim.lsp.buf.formatting_sync(nil, wait_ms)
    else
        vim.lsp.buf.format({
            timeout_ms = wait_ms,
        })
    end
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
    for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
            else
                vim.lsp.buf.execute_command(r.command)
            end
        end
    end
end
 
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function(args)
        goFormatAndImports(3000)
    end,
})
