# Dotfiles

Personal configuration files managed with [chezmoi](https://www.chezmoi.io/).

## Features

- **Shell**: Nushell with Zsh fallback
- **Editor**: Neovim with custom configuration
- **Terminal**: WezTerm + Zellij (with Tmux as alternative)
- **Prompt**: Starship cross-shell prompt
- **AI Coding**: OpenCode (replaces Claude Code and Gemini CLI)
- **Git**: Enhanced configuration with delta diff viewer and 60+ aliases
- **Tools**: fd, bat, ripgrep, eza, zoxide, atuin, delta, and more

## Prerequisites

- [Git](https://git-scm.com/)
- [chezmoi](https://www.chezmoi.io/install/)
- Curl
- Build tools

## Install

```bash
chezmoi init --apply https://github.com/yourusername/dotfiles.git
```

Or from a local copy:

```bash
git clone --recurse-submodules https://github.com/yourusername/dotfiles.git ~/.local/share/chezmoi
chezmoi apply
```

`chezmoi apply` will:
- Create all configuration files
- Install Rust toolchain and cargo packages (fd, bat, ripgrep, starship, atuin, zoxide, eza, delta, gitui, etc.)
- Install essential CLI tools (fzf, jq, yq, direnv, htop, thefuck, git-extras)
- Install git-secrets and configure it globally
- Install intelli-shell (AI-powered command suggestions)
- Setup shell integrations (zoxide, atuin)

*(Tool installation runs via chezmoi's `run_once_*` scripts on first apply.)*

## Updating

```bash
chezmoi update  # pulls latest and applies
```

Or manually:

```bash
cd ~/.local/share/chezmoi
git pull --rebase --recurse-submodules
git submodule update --init --recursive
chezmoi apply
```

## Customization

Create local overrides that won't be committed:
- `~/.gitconfig.local` — Git local config
- `~/.config/nushell/local.nu` — Nushell local config
- `~/.config/nushell/local-env.nu` — Nushell local env override
- `~/.zshrc.local` — Zsh local config
- `~/.config/opencode/opencode.jsonc` — OpenCode local configuration
- `~/.config/opencode/settings.json` — OpenCode machine-specific settings

## Migration from Dotbot

This repo migrated from [dotbot](https://github.com/anishathalye/dotbot) to chezmoi in July 2026.

Key changes:
- Source directory: `~/.dotfiles` → `~/.local/share/chezmoi` (symlinked for backward compat)
- File naming follows chezmoi conventions (`dot_zshrc`, `dot_config/nvim/`, etc.)
- Old `install` script and `install.conf.yaml` replaced by chezmoi's declarative management
- nushell dual-link (`.config/nushell/` + `Library/Application Support/nushell/`) handled via auto-symlink script
- Full git history preserved

## License

MIT License
