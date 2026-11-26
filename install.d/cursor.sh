# Cursor: the vscode-neovim extension, so the nvim config (and its vscode.lua
# branch) drives the editor, plus the one setting the extension wants;
# vscode-clangd for C/C++ navigation; vscode-go for Go; rust-analyzer for Rust.
# The language servers themselves come from pixi.sh (clangd, gopls) and rust.sh
# (rust-analyzer).
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
installed=$(cursor --list-extensions --show-versions 2>/dev/null)
for want in "asvetliakov.vscode-neovim@$VSCODE_NEOVIM_VERSION" \
            "llvm-vs-code-extensions.vscode-clangd@$VSCODE_CLANGD_VERSION" \
            "golang.go@$VSCODE_GO_VERSION" \
            "rust-lang.rust-analyzer@$VSCODE_RUST_ANALYZER_VERSION"; do
  if grep -qxF "$want" <<< "$installed"; then
    skip "$want"
  elif [[ $ME_NO_NET == 1 ]]; then
    partial "not installing $want (--no-net)"
  elif [[ $ME_DRY_RUN == 1 ]]; then
    ok "dry run: would install $want"
  elif cursor --install-extension "$want" --force >/dev/null 2>&1; then
    ok "$want"
  else
    warn "could not install $want; run: cursor --install-extension $want"
  fi
done

# --- settings -------------------------------------------------------------

section settings
case "$(os_name)" in
  macos) settings="$HOME/Library/Application Support/Cursor/User/settings.json" ;;
  *)     settings="$HOME/.config/Cursor/User/settings.json" ;;
esac

# affinity: runs vscode-neovim in its own process so nvim never stalls the
#   editor. Recommended by the vscode-neovim README.
# clangd.path: absolute, because Cursor started from the desktop does not get
#   the shell's PATH. The real binary inside the env, not the ~/.pixi/bin
#   trampoline, so clangd can locate its builtin headers.
# --query-driver: lets clangd run a pixi project's compiler to learn where its
#   standard headers are. Without it, <vector> is not found in pixi builds.
# go.alternateTools: absolute paths for the same reason as clangd.path. Here
#   the ~/.pixi/bin trampolines, not the env binaries: they set GOROOT,
#   GOTOOLCHAIN and PATH exactly as the shell's `go` does.
# rust-analyzer.server.path: rustup's proxy instead of the server bundled in the
#   extension, so it matches the project's toolchain. It finds cargo in
#   ~/.cargo/bin on its own, without the shell's PATH.
merge=$(printf '{"extensions.experimental.affinity": {"asvetliakov.vscode-neovim": 1},
  "clangd.path": "%s/.pixi/envs/clang-tools/bin/clangd",
  "clangd.arguments": ["--query-driver=**/.pixi/envs/*/bin/*"],
  "go.alternateTools": {"go": "%s/.pixi/bin/go", "gopls": "%s/.pixi/bin/gopls"},
  "rust-analyzer.server.path": "%s/.cargo/bin/rust-analyzer"}' \
  "$HOME" "$HOME" "$HOME" "$HOME")

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
  0)  skip "$(prettify "$settings") already has the neovim, clangd, go and rust settings" ;;
  10) if [[ $ME_DRY_RUN == 1 ]]; then
        ok "dry run: would update $(prettify "$settings")"
      else
        ok "updated $(prettify "$settings")"
      fi ;;
  2)  warn "$(prettify "$settings") is not plain JSON; add by hand: $merge" ;;
  *)  warn "could not update $(prettify "$settings")" ;;
esac
