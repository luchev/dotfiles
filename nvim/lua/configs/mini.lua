return function()
  require("mini.surround").setup()
  require("mini.ai").setup()
  require("mini.pairs").setup()
  require("mini.bufremove").setup()
  require("mini.indentscope").setup {
    symbol = "│",
    options = { try_as_border = true },
    draw = {
      animation = function()
        return 0
      end,
    },
  }
  require("mini.move").setup()
end
