# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/home/luchev/.oh-my-zsh"

# Fix the locale of the shell, without relying on locale.conf
export LANG=en_US.utf8
export LC_ALL=en_US.utf8

# Startup instructions
# Make holding a key down input faster
xset r rate 200 60

# Map caps lock to ESC
xmodmap ~/.speedswapper 2>/dev/null

# Remove trailing % at the end of output which doesn't end with new line
PROMPT_EOL_MARK=''

# Theme selection
# ZSH_THEME="random"
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# ZSH_THEME="robbyrussell"
ZSH_THEME="igorsilva"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(sudo git extract z k zsh-autosuggestions colored-man-pages docker golang npm rust cargo pip)

source $ZSH/oh-my-zsh.sh

# Cargo locally installed packages
export PATH=/home/luchev/.cargo/bin:$PATH

# export MANPATH="/usr/local/man:$MANPATH"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Aliases
alias cs="colorls"
alias open="xdg-open"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ls="ls --color=auto"
alias k="k -h"

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

# Custom functions

# Create a file with sub directories (combines mkdir -p and touch)
function touchp () {
    if [ ! "$1" ] ; then
        echo "touchp: missing directory/file operand"
        exit 1
    fi

    local DIRECTORY=${1%/*}
    if [ "$DIRECTORY" != "$1" ] ; then
        mkdir -p "$DIRECTORY"
    fi

    touch "$1"
}
