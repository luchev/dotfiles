.PHONY: install update update-submodules test backup clean help

help:  ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install:  ## Install dotfiles using dotbot
	./install

update:  ## Update dotfiles and reinstall
	@echo "Updating dotfiles repository..."
	git pull --rebase --recurse-submodules
	@echo "Updating submodules..."
	git submodule update --init --recursive
	@echo "Updating Rust..."
	rustup update stable
	@echo "Reinstalling dotfiles..."
	./install
	@echo "Done! ✨"

update-submodules:  ## Update git submodules to latest versions
	@echo "Updating submodules to latest..."
	git submodule update --remote --merge
	@echo "Submodules updated!"

test:  ## Run tests to validate configuration
	@echo "Running configuration tests..."
	./scripts/test.sh

backup:  ## Backup existing dotfiles before installation
	@echo "Creating backup in ~/.dotfiles-backup..."
	@mkdir -p ~/.dotfiles-backup
	@for file in .zshrc .vimrc .tmux.conf .gitconfig .profile; do \
		if [ -f ~/$$file ]; then \
			cp ~/$$file ~/.dotfiles-backup/$$(date +%Y%m%d-%H%M%S)-$$file; \
			echo "Backed up $$file"; \
		fi \
	done
	@for dir in .config/nvim .config/nushell .config/alacritty .config/zellij; do \
		if [ -d ~/$$dir ]; then \
			cp -r ~/$$dir ~/.dotfiles-backup/$$(date +%Y%m%d-%H%M%S)-$$(basename $$dir); \
			echo "Backed up $$dir"; \
		fi \
	done
	@echo "Backup complete!"

clean:  ## Clean up broken symlinks in home directory
	@echo "Cleaning broken symlinks..."
	@find ~ -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@find ~/.config -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@echo "Cleanup complete!"

