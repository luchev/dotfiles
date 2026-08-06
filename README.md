# Dotfiles

Personal configuration files managed with [dotbot](https://github.com/anishathalye/dotbot).

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
- Python 3 (dotbot runtime)
- Curl
- Build tools

## Install

```bash
git clone --recurse-submodules https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

`./install` symlinks every config into `$HOME` and runs the core setup steps
(claude settings merge, cross-symlinks, nushell dual-link, zellij workspace,
shell integrations). It does **not** install packages.

To also install packages (Rust toolchain, cargo/brew/npm/python tools,
git addons, claude-mem, impeccable, intelli-shell, zellij plugins):

```bash
./install --packages
```

Each installer is idempotent and skips what is already present.

## Updating

```bash
cd ~/.dotfiles
git pull --rebase --recurse-submodules
git submodule update --init --recursive
./install
```

Because targets are symlinks into this repo, editing a file here updates the live
config immediately — `./install` is only needed to add new files or relink.

## Customization

Create local overrides that won't be committed:
- `~/.config/nushell/local.nu` — Nushell local config
- `~/.config/nushell/local-env.nu` — Nushell local env override
- `~/.config-local.nu` — local secrets / env (sourced by config.nu, untracked)

The OpenCode config picks a variant by machine: work machines (those with a
`~/.dotfiles-work` checkout) get `config/opencode/opencode.work.jsonc`, everyone
else gets `config/opencode/opencode.jsonc`. `setup/link-opencode-jsonc.sh` links
the right one.

`~/.claude/settings.json` is **not** symlinked — an external tool owns most of it,
so `setup/merge-claude-settings.sh` merges in only the personal keys on each apply.

### Private npm registry (opt-in)

`~/.bunfig.toml` is generated only when a registry URL is supplied at apply time:

```bash
NPM_REGISTRY_URL=https://registry.example.com/ ./install
```

Credentials come from `$NPM_REGISTRY_USER` / `$NPM_REGISTRY_PASS` (set in
`~/.config-local.nu`) and are interpolated by bun at runtime, not written to disk.

## Bitwarden (opt-in)

Secrets are never synced by default. The Bitwarden steps no-op unless
`DOTBOT_BITWARDEN` is set. Prerequisites: the [`bw`](https://bitwarden.com/help/cli/)
CLI installed and an unlocked vault:

```bash
export BW_SESSION=$(bw unlock --raw)
```

Restore SSH keys (`~/.ssh/*`, then `ssh-add`):

```bash
DOTBOT_BITWARDEN=1 ./install
```

Also sync env vars into `~/.config-local.nu` — needs the UUID of the Bitwarden item
holding them in its notes field:

```bash
DOTBOT_BITWARDEN=1 BW_ENV_ITEM_UUID=<uuid> ./install
```

Enabled runs fail loudly (non-zero exit) if `bw` is missing, the vault is locked, or
`BW_ENV_ITEM_UUID` is unset.

## Layout

- `config/` — `~/.config/` contents (nushell, nvim, opencode, zellij, lazy-mcp, …)
- `claude/` — `~/.claude/` (hooks, rules, output-styles)
- `Library/` — macOS `~/Library/Application Support/` (ghostty)
- `bin/` — scripts linked into `~/bin`
- `setup/` — shell steps run by `./install`; `setup/packages/` are opt-in installers
- `install.conf.yaml` / `install.packages.yaml` — dotbot configs
- `dotbot/`, `argc-completions/` — git submodules

## License

MIT License
