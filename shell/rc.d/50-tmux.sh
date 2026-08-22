# tmux session helpers. Session-per-project is the workflow: one long-lived
# session per repo, windows inside it.

alias tmls='tmux list-sessions'
alias tmka='tmux kill-session'

# tms [name] -- attach to a session, creating it if needed. With no argument,
# names the session after the current directory. Safe to run inside tmux
# (switches the client instead of refusing to nest).
tms() {
  local name="${1:-$(basename "$PWD")}"
  name="${name//[.:]/-}"   # tmux forbids . and : in session names
  if tmux has-session -t="$name" 2>/dev/null; then
    if [ -n "$TMUX" ]; then tmux switch-client -t "$name"; else tmux attach -t "$name"; fi
  else
    if [ -n "$TMUX" ]; then
      tmux new-session -d -s "$name" -c "$PWD" && tmux switch-client -t "$name"
    else
      tmux new-session -s "$name" -c "$PWD"
    fi
  fi
}

tmks() { tmux kill-session -t "${1:?usage: tmks <session>}"; }

# tmw <name> [index] -- new window in the current session, at an optional index.
tmw() {
  local name="${1:?usage: tmw <name> [index]}"
  if [ -n "$2" ]; then
    tmux new-window -n "$name" -t "$2" -c "$PWD"
  else
    tmux new-window -n "$name" -c "$PWD"
  fi
}

# Interactive session picker; falls back to a plain list without fzf.
tmp() {
  if command -v fzf >/dev/null 2>&1; then
    local sel
    sel=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | fzf --height 40% --reverse) || return
    [ -n "$sel" ] && tms "$sel"
  else
    tmux list-sessions
  fi
}
