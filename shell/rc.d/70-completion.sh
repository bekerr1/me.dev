# Shell completion. Guarded because these files are absent on minimal servers.

if ! shopt -oq posix; then
  if [ -r /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -r /etc/bash_completion ]; then
    . /etc/bash_completion
  elif [ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
    . /opt/homebrew/etc/profile.d/bash_completion.sh
  fi
fi

command -v gh >/dev/null 2>&1 && eval "$(gh completion -s bash)" 2>/dev/null

# Readline behaviour: complete case-insensitively, show the menu on first Tab.
bind 'set completion-ignore-case on' 2>/dev/null
bind 'set show-all-if-ambiguous on' 2>/dev/null
bind 'set colored-stats on' 2>/dev/null

# Up/Down search history using what has already been typed.
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null
