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
- `~/.config/opencode/settings.json` — OpenCode machine-specific settings

The OpenCode config (`~/.config/opencode/opencode.jsonc` and `rate-limit-fallback.json`)
is **chezmoi-managed** (source `dot_config/opencode/`). To change it: edit the source
files, then `chezmoi apply` to sync the target. Do not edit the live files directly
or next `chezmoi apply` won't see them.

## Bitwarden (opt-in)

Secrets are never synced by default. The two Bitwarden scripts are templates that
render to nothing unless `CHEZMOI_BITWARDEN` is set, and chezmoi skips scripts that
render empty.

Prerequisites: the [`bw`](https://bitwarden.com/help/cli/) CLI installed and an
unlocked vault:

```bash
export BW_SESSION=$(bw unlock --raw)
```

Restore SSH keys (`~/.ssh/*`, then `ssh-add`):

```bash
CHEZMOI_BITWARDEN=1 chezmoi apply
```

Also sync env vars into `~/.config-local.nu` — needs the UUID of the Bitwarden item
holding them in its notes field:

```bash
CHEZMOI_BITWARDEN=1 BW_ENV_ITEM_UUID=<uuid> chezmoi apply
```

Enabled runs fail loudly (non-zero exit) if `bw` is missing, the vault is locked, or
`BW_ENV_ITEM_UUID` is unset. The SSH script is `run_once_`, so it only re-runs if its
contents change; force it with `chezmoi state delete-bucket --bucket=scriptState`.

## Migration from Dotbot

This repo migrated from [dotbot](https://github.com/anishathalye/dotbot) to chezmoi in July 2026.

Key changes:
- Source directory: `~/.dotfiles` → `~/.local/share/chezmoi`
- File naming follows chezmoi conventions (`dot_zshrc`, `dot_config/nvim/`, etc.)
- Old `install` script and `install.conf.yaml` replaced by chezmoi's declarative management
- nushell dual-link (`.config/nushell/` + `Library/Application Support/nushell/`) handled via auto-symlink script
- Full git history preserved

## License

MIT License
