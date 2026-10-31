# Git: config, global ignore, and the minimal commit-message editor.

link "$ME_ROOT/git/gitconfig" "$HOME/.gitconfig"

# Identity lives outside the repo so the same checkout works with a work
# identity on one machine and a personal one on another.
if [[ ! -f "$ME_STATE/gitconfig.local" ]]; then
  write_if_changed "$ME_STATE/gitconfig.local" <<'GITLOCAL'
# Machine-local git config. Not tracked.
[user]
	name = Brendan Kerr
	email = bkerrcloud@icloud.com
GITLOCAL
else
  skip "$(prettify "$ME_STATE/gitconfig.local") exists"
fi

if have delta; then
  info "delta found -- add '[core] pager = delta' to gitconfig.local to use it"
fi
