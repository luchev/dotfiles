local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font_size = 16.0
config.color_scheme = 'Molokai'
config.window_background_opacity = 0.9
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.enable_tab_bar = false
config.scrollback_lines = 10000
config.term = 'xterm-256color'
config.default_prog = { '/opt/homebrew/bin/nu', '--config', '~/.dotfiles/config.nu', '--env-config', '~/.dotfiles/env.nu' }

return config

