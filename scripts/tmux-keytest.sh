#!/usr/bin/env bash
#
# Bisect a "prefix needs two presses" problem.
#
# Key handling cannot be tested from another process -- send-keys bypasses
# bindings, so the keystroke has to come from a real terminal. This spins up
# isolated tmux servers (own socket, own config, your sessions untouched) with
# progressively more of the config loaded, so you can find the level where the
# behaviour changes.
#
#   ./scripts/tmux-keytest.sh 1     bare minimum: prefix + one binding
#   ./scripts/tmux-keytest.sh 2     + the rest of 00-options.conf
#   ./scripts/tmux-keytest.sh 3     + 10-keys.conf
#   ./scripts/tmux-keytest.sh 4     + status bar and nested (the full config)
#
# In each: press C-e ONCE, then t. A "name:" prompt at the bottom means one
# press was enough. The status bar also shows the live key table.
# Press C-e d (or C-e C-e d) to detach.

set -euo pipefail

ME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEVEL="${1:-1}"
SOCK="keytest$LEVEL"
CONF="$(mktemp /tmp/me-keytest-XXXX.conf)"
trap 'rm -f "$CONF"' EXIT

# A loud, always-refreshing readout of the key table. status-interval 1 means
# it updates even if the prefix-change redraw is itself the thing misbehaving.
readout() {
  cat <<'EOF'
set -g status on
set -g status-interval 1
set -g status-position bottom
set -g status-style 'bg=#282727,fg=#c5c9c5'
set -g status-right-length 70
set -g status-left ''
set -g status-right '#[bg=#{?client_prefix,#c4746e,#282727}] key-table=#{client_key_table}  prefix=#{client_prefix} '
EOF
}

case "$LEVEL" in
  1)
    cat > "$CONF" <<'EOF'
# Bare minimum. If C-e needs two presses HERE, nothing in this repo is at fault
# -- it is the terminal or something outside tmux.
set -g prefix C-e
unbind C-b
bind C-e last-window
bind t command-prompt -p 'name:' 'new-window -n "%%"'
EOF
    readout >> "$CONF"
    ;;
  2)
    printf 'source-file %s/tmux/conf.d/00-options.conf\n' "$ME_ROOT" > "$CONF"
    cat >> "$CONF" <<'EOF'
bind t command-prompt -p 'name:' 'new-window -n "%%"'
EOF
    readout >> "$CONF"
    ;;
  3)
    for f in 00-options 10-keys; do
      printf 'source-file %s/tmux/conf.d/%s.conf\n' "$ME_ROOT" "$f" >> "$CONF"
    done
    readout >> "$CONF"
    ;;
  4)
    for f in 00-options 10-keys 20-status 30-nested; do
      printf 'source-file %s/tmux/conf.d/%s.conf\n' "$ME_ROOT" "$f" >> "$CONF"
    done
    # No readout override -- this is the real config, status bar included.
    ;;
  *)
    echo "usage: $0 <1|2|3|4>" >&2; exit 1 ;;
esac

tmux -L "$SOCK" kill-server 2>/dev/null || true

cat <<EOF

  level $LEVEL  --  isolated server on socket '$SOCK'
  your own sessions are on the 'default' socket and are not touched

  press C-e ONCE, then t
    -> a "name:" prompt appears  = one press is enough
    -> nothing happens           = the first press was eaten

  the status bar on the right shows the live key table
  detach with C-e d

EOF
read -rp "  enter to start... " _

tmux -L "$SOCK" -f "$CONF" new-session -A -s keytest

echo
echo "  detached. clean up with: tmux -L $SOCK kill-server"
