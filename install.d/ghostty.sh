# Ghostty: the terminal config. The app itself is installed by the packages
# module; the config is linked whether or not it is installed yet, the same as
# tmux and nvim.

have ghostty || warn "ghostty is not installed; the config will be linked anyway"

# config.ghostty is the file name Ghostty 1.3 creates and reads.
link "$ME_ROOT/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"

if have ghostty && [[ $ME_DRY_RUN != 1 ]]; then
  if out=$(ghostty +validate-config --config-file="$ME_ROOT/ghostty/config.ghostty" 2>&1); then
    info "ghostty config is valid"
  else
    warn "ghostty config has errors: $out"
  fi
fi
