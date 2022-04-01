unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

bind v split-window -h
bind f split-window -v
unbind '"'
unbind %

set -g status-keys vi
setw -g mode-keys vi

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# default statusbar colors
set-option -g status-style fg=colour136,bg=colour235 #yellow and base02

# default window title colors
set-window-option -g window-status-style fg=colour244,bg=default #base0 and default
#set-window-option -g window-status-style dim

# active window title colors
set-window-option -g window-status-current-style fg=colour166,bg=default #orange and default
#set-window-option -g window-status-current-style bright

# pane border
set-option -g pane-border-style fg=colour235 #base02
set-option -g pane-active-border-style fg=colour240 #base01

# message text
set-option -g message-style fg=colour166,bg=colour235 #orange and base02

# pane number display
set-option -g display-panes-active-colour colour33 #blue
set-option -g display-panes-colour colour166 #orange

# clock
set-window-option -g clock-mode-colour colour64 #green

# bell
set-window-option -g window-status-bell-style fg=colour235,bg=colour160 #base02, red

