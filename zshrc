# Path to oh-my-zsh config
export ZSH=$HOME'/.oh-my-zsh'

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8


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
export PATH=/opt/homebrew/opt/openjdk@17/bin:$HOME/.local/bin/diff-so-fancy:$HOME/.cargo/bin:$HOME/.local/bin:${KREW_ROOT:-$HOME/.krew}/bin:$PATH

# Preferred editor
export EDITOR='nvim'

# Aliases
alias v='nvim'
alias g='git'
alias e='eza'
alias h='hstr'
alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias ls='ls --color=auto'
alias k='k -h'

# Git aliases
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

# Tmux aliases
alias ta='tmux a -t'
alias tn='tmux new -s'

# Required so some tools like bazel and go, which have '...' argumeents work correctly
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

# Load starship
eval "$(starship init zsh)"
# Load direnv
eval "$(direnv hook zsh)"

source /Users/z/.docker/init-zsh.sh || true # Added by Docker Desktop
