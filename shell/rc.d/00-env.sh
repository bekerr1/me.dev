# Core environment. Loaded first; later modules may depend on these.

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-FRX'          # quit-if-one-screen, keep colors, no altscreen wipe
export MANPAGER='less -FRX'

# Do not force TERM. Terminals set it correctly; overriding it breaks colors and
# keys over ssh. tmux sets its own via tmux.conf.

# History: large, deduped, appended (not clobbered) across concurrent shells.
export HISTSIZE=100000
export HISTFILESIZE=200000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE='ls:ll:cd:pwd:exit:clear:history'
export HISTTIMEFORMAT='%F %T  '
shopt -s histappend
shopt -s cmdhist

shopt -s checkwinsize       # keep $LINES/$COLUMNS right after a resize
shopt -s globstar 2>/dev/null || true   # ** recursion (bash 4+; macOS 3.2 lacks it)
shopt -s no_empty_cmd_completion

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"
