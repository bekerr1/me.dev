# tmux: single config entry point at ~/.tmux.conf, fragments sourced by path.

have tmux || warn "tmux is not installed; the config will be linked anyway"

link "$ME_ROOT/tmux/tmux.conf" "$HOME/.tmux.conf"

# tmux 3.1+ also reads ~/.config/tmux/tmux.conf and prefers it. Link both so the
# right one is found regardless of version.
link "$ME_ROOT/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

if have tmux; then
  ver=$(tmux -V | sed 's/[^0-9.]*//g')
  case "$ver" in
    1.*|2.*) warn "tmux $ver is too old for this config (needs 3.0+); upgrade it" ;;
    *)       ok "tmux $ver" ;;
  esac

  # Reload live servers so the change takes effect without detaching.
  if [[ $ME_DRY_RUN != 1 ]] && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null && ok "reloaded running tmux servers"
  fi
fi
