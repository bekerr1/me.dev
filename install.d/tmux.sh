# tmux: single config entry point at ~/.tmux.conf, fragments sourced by path,
# plus the persistence plugins as pinned clones.

# shellcheck disable=SC1091
. "$ME_ROOT/tools.env"

have tmux || warn "tmux is not installed; the config will be linked anyway"

link "$ME_ROOT/tmux/tmux.conf" "$HOME/.tmux.conf"

# tmux 3.1+ also reads ~/.config/tmux/tmux.conf and prefers it. Link both so the
# right one is found regardless of version.
link "$ME_ROOT/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Persistence plugins. Cloned directly rather than through TPM, which needs an
# interactive `prefix + I` and would break an unattended install.
if [[ $ME_NO_NET == 1 ]]; then
  skip "not fetching tmux plugins (--no-net)"
else
  clone_pinned tmux-resurrect "$TMUX_RESURRECT_REPO" "$TMUX_RESURRECT_REF" \
    "$TMUX_PLUGIN_DIR/tmux-resurrect"
  clone_pinned tmux-continuum "$TMUX_CONTINUUM_REPO" "$TMUX_CONTINUUM_REF" \
    "$TMUX_PLUGIN_DIR/tmux-continuum"
  run mkdir -p "$HOME/.local/share/tmux/resurrect"
fi

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
