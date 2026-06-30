# Dotfiles Environment

Context for working in this dotfiles repository.

## Environment

- **Dotfiles manager:** [Dotbot](https://github.com/anishathalye/dotbot). Always update `install.conf.yaml` when adding or moving configuration files.
- **Primary shell:** Nushell (`nu`). Prefer Nushell-native commands and syntax for scripting.
- **Editor:** Neovim (`nvim`).
- **Terminal:** WezTerm + Zellij.
- **Key tools:** `argc` (completions), `atuin` (history), `starship` (prompt), `zoxide` (navigation), `carapace` (completions).
- **Package managers:** `brew` (macOS), `cargo` (Rust), `npm` (Node).

## Project Structure

- `nushell/` — Nushell configuration.
- `claude/` — Claude Code settings, agents, skills, and guidance notes.
- `gemini/` — Gemini CLI configuration and policies.
- `nvim/` — Neovim configuration.
- `argc-completions/` — custom shell completions.

## Command Execution

- When asked to "install" something, check `install.conf.yaml` first to see if it belongs in the automation.
- Prefer non-interactive flags; interactive prompts don't work well in this environment.
- Run sequential operations in order; don't chain dependent steps that may be backgrounded.
- `config.nu` and other linked files are symlinks into this repo — edit the real target under `~/.dotfiles`, not the symlink.
