return function()
  require("mini.surround").setup()
  require("mini.ai").setup()
  require("mini.pairs").setup()
  require("mini.bufremove").setup()
  require("mini.move").setup()

  require("mini.animate").setup {
    -- cursor trail disabled: Ghostty's cursor_warp shader already animates the
    -- cursor at the terminal level; running both double-renders the trail.
    cursor = { enable = false },
    -- float open/close animations disabled: they make cmp/which-key/noice
    -- popups feel laggy. Smooth scroll + window resize stay enabled (defaults).
    open = { enable = false },
    close = { enable = false },
  }
end
