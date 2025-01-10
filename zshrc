# Clone antidote plugin manager if necessary.
[[ -d ${ZDOTDIR:-~}/.antidote ]] ||
  git clone https://github.com/mattmc3/antidote ${ZDOTDIR:-~}/.antidote

# Create an amazing Zsh config using antidote plugins
source ${ZDOTDIR:-~}/.antidote/antidote.zsh
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt

# PATH
export PATH=/opt/homebrew/bin:/opt/homebrew/opt/openjdk@17/bin:$HOME/.local/bin/diff-so-fancy:$HOME/.cargo/bin:$HOME/.local/bin:${KREW_ROOT:-$HOME/.krew}/bin:$PATH

# Language settings for Mac
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
# Disable --auto-update for homebrew
HOMEBREW_NO_AUTO_UPDATE=1

# Preferred editor
export EDITOR='nvim'

# Aliases
alias v='nvim'
alias g='git'
alias e='eza --color=auto'
alias h='hstr'
alias f='fd'
alias b='bat'
alias rg='rg --color=auto'
alias cat='bat'
alias find='fd'
alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias ls='ls --color=auto'
alias -- -='cd -'
alias ..='cd ..'

# Tmux aliases
alias ta='tmux a -t'
alias tn='tmux new -s'

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
# Fuck
eval "$(thefuck --alias &>/dev/null)"
# Zoxide
eval "$(zoxide init zsh)"

test -f '~/.docker/init-zsh.sh' && source ~/.docker/init-zsh.sh || true # Added by Docker Desktop

