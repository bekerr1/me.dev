# Neovim: link the config and let lazy.nvim fetch plugins on first launch.

link "$ME_ROOT/nvim" "$HOME/.config/nvim"

if have nvim; then
  ver=$(nvim --version | head -1 | sed 's/^NVIM v//')
  case "$ver" in
    0.[0-9].*)
      case "$ver" in
        0.1[0-9]*) ok "neovim $ver" ;;
        *) warn "neovim $ver is older than 0.10; treesitter and gitsigns need 0.10+" ;;
      esac ;;
    *) ok "neovim $ver" ;;
  esac
else
  warn "neovim is not installed; config linked but unusable until it is"
fi

# rg powers telescope's live_grep. Without it grep falls back to something slow
# enough that you will stop using the picker.
have rg || warn "ripgrep not found -- telescope live_grep will be very slow"

if [[ $ME_MINIMAL == 1 || $ME_NO_NET == 1 ]]; then
  skip "not syncing plugins (--minimal/--no-net)"
elif [[ $ME_DRY_RUN == 1 ]]; then
  skip "dry run: not syncing plugins"
elif have nvim; then
  log "  syncing plugins (first run clones lazy.nvim; this takes a minute)"
  nvim --headless "+Lazy! sync" +qa 2>&1 | tail -3 || warn "plugin sync reported errors; run :Lazy in nvim to inspect"
  ok "plugins synced"
fi
