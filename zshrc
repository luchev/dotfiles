# Install zsh if missing
if [ ! -d "${HOME}/.oh-my-zsh" ] ; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh plugins if missing
if [ ! -d  "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

if [ ! -d  "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

if [ ! -f "${HOME}/.local/share/nvim/site/autoload/plug.vim" ]; then
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    nvim -c ":PlugInstall" -c ":qa!"
fi

# Path to oh-my-zsh config
export ZSH=$HOME'/.oh-my-zsh'

# Map Caps to Esc
setxkbmap -option caps:escape
# Set the locale of the shell, without relying on locale.conf
export LANG=en_US.utf8
export LC_ALL=en_US.utf8

# Remove trailing % at the end of output which doesn't end with new line
PROMPT_EOL_MARK=''

# Hyphen-insensitive completion.
HYPHEN_INSENSITIVE='true'

# Make repository status check for large repositories faster
DISABLE_UNTRACKED_FILES_DIRTY='true'

# History timestamp
HIST_STAMPS='yyyy-mm-dd'

# Plugins
plugins=(extract z zsh-autosuggestions zsh-syntax-highlighting)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# PATH
# - Local cargo packages
export PATH=/home/luchev/.cargo/bin:$PATH

# Preferred editor
export EDITOR='nvim'

# Aliases
alias v='nvim'
alias open='xdg-open'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ls='ls --color=auto'
alias k='k -h'

unalias '...'

# Custom format for the time function
TIMEFMT='%J'$'\n'\
'user time:                 %U'$'\n'\
'system time                %S'$'\n'\
'total time:                %*E'$'\n'\
'cpu time:                  %P'$'\n'\
'avg shared (code):         %X KB'$'\n'\
'avg unshared (data/stack): %D KB'$'\n'\
'total (sum):               %K KB'$'\n'\
'max memory:                %M MB'$'\n'\
'page faults from disk:     %F'$'\n'\
'other page faults:         %R'

# Create a file with sub directories (combines mkdir -p and touch)
function touchp () {
    if [ ! '$1' ] ; then
        echo 'touchp: missing directory/file operand'
        exit 1
    fi

    local DIRECTORY=${1%/*}
    if [ '$DIRECTORY' != '$1' ] ; then
        mkdir -p '$DIRECTORY'
    fi

    touch '$1'
}

alias gst='git status'
alias gco='git checkout'
alias gc='git commit'
alias gcv='git commit verbose'
alias ga='git add'
alias gb='git branch'
alias gd='git diff'
alias gp='git pull --rebase'
alias gs='git stash'
alias gr='git rebase'

alias ta='tmux a -t'
alias tn='tmux new -s'


# Load starship
if ! which starship ; then
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -s '-f' >/dev/null 2>&1
fi
eval "$(starship init zsh)"

