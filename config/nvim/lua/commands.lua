vim.api.nvim_create_user_command("DiagnosticToggle", function()
	-- Inline diagnostics are rendered by tiny-inline-diagnostic, not native
	-- virtual_text (which is kept off to avoid duplicate display).
	require("tiny-inline-diagnostic").toggle()
	local underline = vim.diagnostic.config().underline
	vim.diagnostic.config {
		underline = not underline,
		signs = not underline,
		virtual_text = false,
	}
end, { desc = "toggle diagnostics (inline + signs + underline)" })

