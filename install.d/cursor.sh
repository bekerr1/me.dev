# Cursor: the vscode-neovim extension, so the nvim config (and its vscode.lua
# branch) drives the editor, plus the one setting the extension wants.
#
# Cursor rewrites settings.json from its own UI, so it is not linked from the
# repo. The installer merges in only the keys below and leaves the rest alone.
# Neither the extension nor the setting is pruned if removed from here, the
# same rule as system packages.

# shellcheck disable=SC1091
. "$ME_ROOT/tools.env"

if ! have cursor; then
  skip "cursor not installed"
  return 0
fi

# --- extension ------------------------------------------------------------

section extension
ext="asvetliakov.vscode-neovim"
if cursor --list-extensions --show-versions 2>/dev/null | grep -qxF "$ext@$VSCODE_NEOVIM_VERSION"; then
  skip "$ext $VSCODE_NEOVIM_VERSION"
elif [[ $ME_NO_NET == 1 ]]; then
  partial "not installing $ext (--no-net)"
elif [[ $ME_DRY_RUN == 1 ]]; then
  ok "dry run: would install $ext@$VSCODE_NEOVIM_VERSION"
elif cursor --install-extension "$ext@$VSCODE_NEOVIM_VERSION" --force >/dev/null 2>&1; then
  ok "$ext $VSCODE_NEOVIM_VERSION"
else
  warn "could not install $ext; run: cursor --install-extension $ext@$VSCODE_NEOVIM_VERSION"
fi

# --- settings -------------------------------------------------------------

section settings
case "$(os_name)" in
  macos) settings="$HOME/Library/Application Support/Cursor/User/settings.json" ;;
  *)     settings="$HOME/.config/Cursor/User/settings.json" ;;
esac

# Runs the extension in its own process so nvim never stalls the editor.
# Recommended by the vscode-neovim README.
merge='{"extensions.experimental.affinity": {"asvetliakov.vscode-neovim": 1}}'

if ! have python3; then
  warn "python3 not found; add to $(prettify "$settings"): $merge"
  return 0
fi

# Exit codes: 0 already set, 10 would change, 2 unparseable (comments or
# trailing commas, which settings.json allows but json does not).
merge_settings() {
  python3 - "$settings" "$merge" "$1" <<'EOF'
import json, os, sys
path, merge, write = sys.argv[1], json.loads(sys.argv[2]), sys.argv[3] == "1"
try:
    with open(path) as f:
        cur = json.load(f)
except FileNotFoundError:
    cur = {}
except ValueError:
    sys.exit(2)
# One level deep, so other extensions' affinity entries survive.
new = dict(cur)
for k, v in merge.items():
    old = new.get(k)
    new[k] = {**old, **v} if isinstance(old, dict) and isinstance(v, dict) else v
if new == cur:
    sys.exit(0)
if write:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".tmp", "w") as f:
        json.dump(new, f, indent=4)
        f.write("\n")
    os.replace(path + ".tmp", path)
sys.exit(10)
EOF
}

rc=0
merge_settings "$([[ $ME_DRY_RUN == 1 ]] && echo 0 || echo 1)" || rc=$?
case $rc in
  0)  skip "$(prettify "$settings") already has the vscode-neovim settings" ;;
  10) if [[ $ME_DRY_RUN == 1 ]]; then
        ok "dry run: would update $(prettify "$settings")"
      else
        ok "updated $(prettify "$settings")"
      fi ;;
  2)  warn "$(prettify "$settings") is not plain JSON; add by hand: $merge" ;;
  *)  warn "could not update $(prettify "$settings")" ;;
esac
