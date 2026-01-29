# Dotfiles

Personal configuration files for a productive development environment across Linux and macOS.

## Features

- **Shell**: Nushell with Zsh fallback
- **Editor**: Neovim with custom configuration
- **Terminal**: Alacritty, WezTerm, and Termux support
- **Multiplexer**: Tmux and Zellij configurations
- **Prompt**: Starship cross-shell prompt
- **Git**: Enhanced configuration with powerful aliases
- **Tools**: fd, bat, ripgrep, eza, zoxide, atuin, and more

## Quick Start

### Prerequisites

- Git
- Curl
- Build tools (build-essential on Debian/Ubuntu, base-devel on Arch)
- Python 3
- Rust/Cargo (optional, will be installed automatically)

### Installation

```bash
# Clone repository
git clone --recurse-submodules https://github.com/yourusername/dotfiles ~/.dotfiles

# Install
cd ~/.dotfiles
./install
```

