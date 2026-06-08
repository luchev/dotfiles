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
config.default_prog = { '/opt/homebrew/bin/nu', '--config', '~/.dotfiles/nushell/config.nu', '--env-config', '~/.dotfiles/nushell/env.nu' }
config.audible_bell = 'Disabled'
config.status_update_interval = 5000

local function is_ssh_active(pane)
  local process_name = pane:get_foreground_process_name()
  if process_name and process_name:lower():find("ssh") then
    return true
  end
  local user_vars = pane:get_user_vars()
  return user_vars.SSH_MOCK == "1"
end

wezterm.on('update-status', function(window, pane)
  if is_ssh_active(pane) then
    window:set_right_status(wezterm.format {
      { Text = ' 󰣀 ' },
    })
  else
    window:set_right_status('')
  end
end)

return config

