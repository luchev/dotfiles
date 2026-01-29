# Dotfiles

Personal configuration files for a productive development environment across Linux and macOS.

## Features

- **Shell**: Nushell with Zsh fallback
- **Editor**: Neovim with custom configuration
- **Terminal**: Alacritty, WezTerm, and Termux support
- **Multiplexer**: Tmux and Zellij configurations
- **Prompt**: Starship cross-shell prompt
- **Git**: Enhanced configuration with delta diff viewer and 60+ aliases
- **Tools**: fd, bat, ripgrep, eza, zoxide, atuin, delta, and more

## Installation

### Prerequisites

- Git
- Curl
- Build tools (build-essential on Debian/Ubuntu, base-devel on Arch)
- Python 3

### Install

```bash
git clone --recurse-submodules https://github.com/yourusername/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install
```

The install script will:
- Install Rust toolchain (if needed)
- Symlink all configuration files
- Install cargo packages (fd, bat, ripgrep, starship, atuin, zoxide, eza, delta, gitui, etc.)
- Install git addons (git-secrets, git-extras, git-stats, commitizen)
- Install intelli-shell (AI-powered command suggestions)
- Setup shell integrations (zoxide, atuin)
- Configure git-secrets globally to prevent committing secrets

## Updating

```bash
cd ~/.dotfiles
git pull --rebase --recurse-submodules
git submodule update --init --recursive
./install
```

## Customization

Create local overrides that won't be committed:
- `~/.gitconfig.local` - Git local config
- `~/.config/nushell/config.local.nu` - Nushell local config
- `~/.zshrc.local` - Zsh local config

## License

MIT License

