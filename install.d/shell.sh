# Shell: bashrc/bash_profile loaders plus the machine-local stubs.

link "$ME_ROOT/shell/bashrc" "$HOME/.bashrc"
link "$ME_ROOT/shell/bash_profile" "$HOME/.bash_profile"

# A login shell on some systems reads ~/.profile instead. Point it at the same place.
if [[ ! -e "$HOME/.profile" || -L "$HOME/.profile" ]]; then
  link "$ME_ROOT/shell/bash_profile" "$HOME/.profile"
fi

# secrets.env: real credentials, never tracked, readable only by the owner.
if [[ ! -f "$ME_STATE/secrets.env" ]]; then
  run cp "$ME_ROOT/shell/secrets.env.example" "$ME_STATE/secrets.env"
  run chmod 600 "$ME_STATE/secrets.env"
  ok "created $(prettify "$ME_STATE/secrets.env") from the example"
else
  run chmod 600 "$ME_STATE/secrets.env"
  skip "$(prettify "$ME_STATE/secrets.env") exists"
fi

# local.sh: host-specific PATH entries, conda/rbenv init, one-off aliases.
if [[ ! -f "$ME_STATE/local.sh" ]]; then
  write_if_changed "$ME_STATE/local.sh" <<'LOCAL'
# Machine-local shell config. Not tracked by git.
# Anything here that turns out to be useful everywhere belongs in the repo.
LOCAL
else
  skip "$(prettify "$ME_STATE/local.sh") exists"
fi
