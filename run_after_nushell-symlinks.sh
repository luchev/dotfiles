#!/bin/bash
# Create nushell dual-link symlinks for macOS
# Primary files at ~/.config/nushell/ -> symlink at ~/Library/Application Support/nushell/
mkdir -p "$HOME/Library/Application Support/nushell"
ln -sf "$HOME/.config/nushell/config.nu" "$HOME/Library/Application Support/nushell/config.nu"
ln -sf "$HOME/.config/nushell/env.nu" "$HOME/Library/Application Support/nushell/env.nu"
