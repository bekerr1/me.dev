#!/usr/bin/env bash
# Shared helpers for install.d/* modules. Sourced, never executed directly.

ME_ROOT="${ME_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ME_STATE="${ME_STATE:-$HOME/.config/me}"
ME_BACKUP="${ME_BACKUP:-$HOME/.me-backup}"

# Flags, set by install.sh
ME_DRY_RUN="${ME_DRY_RUN:-0}"
ME_MINIMAL="${ME_MINIMAL:-0}"
ME_NO_NET="${ME_NO_NET:-0}"

if [[ -t 1 ]]; then
  _c_reset=$'\033[0m'; _c_dim=$'\033[2m'; _c_red=$'\033[31m'
  _c_grn=$'\033[32m'; _c_ylw=$'\033[33m'; _c_blu=$'\033[34m'
else
  _c_reset=; _c_dim=; _c_red=; _c_grn=; _c_ylw=; _c_blu=
fi

# ok   = something changed      (counted)
# info = a status line, no change
# skip = already in the desired state
# warn = needs attention          (counted)
ME_CHANGES=0
ME_WARNINGS=0
log()  { printf '%s==>%s %s\n' "$_c_blu" "$_c_reset" "$*"; }
ok()   { printf '  %s✓%s %s\n'  "$_c_grn" "$_c_reset" "$*"; ME_CHANGES=$((ME_CHANGES + 1)); }
info() { printf '  %s✓%s %s\n'  "$_c_dim" "$_c_reset" "$*"; }
skip() { printf '  %s·%s %s\n'  "$_c_dim" "$_c_reset" "$*"; }
warn() { printf '  %s!%s %s\n'  "$_c_ylw" "$_c_reset" "$*" >&2; ME_WARNINGS=$((ME_WARNINGS + 1)); }
die()  { printf '%serror:%s %s\n' "$_c_red" "$_c_reset" "$*" >&2; exit 1; }

run() {
  if [[ $ME_DRY_RUN == 1 ]]; then
    printf '  %sdry-run:%s %s\n' "$_c_dim" "$_c_reset" "$*"
  else
    "$@"
  fi
}

os_name() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)  echo linux ;;
    *)      echo unknown ;;
  esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# pkg_install <pkg[:cmd]>...  -- install whichever of these are missing.
pkg_install() {
  local missing=() spec p
  for spec in "$@"; do
    p="${spec%%:*}"
    if have "${spec##*:}"; then skip "$p"; else missing+=("$p"); fi
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  if [[ $ME_NO_NET == 1 ]]; then
    partial
    warn "missing: ${missing[*]} (not installing with --no-net)"
    return 0
  fi

  case "$(os_name)" in
    macos)
      if ! have brew; then
        warn "missing: ${missing[*]} -- install Homebrew first: https://brew.sh"
        return 0
      fi
      for p in "${missing[@]}"; do
        case "$p" in
          ghostty|docker-desktop) run brew install --cask "$p" ;;
          *)       run brew install "$p" ;;
        esac && ok "$p"
      done
      ;;
    linux)
      if ! have apt-get; then
        warn "missing: ${missing[*]} -- no apt-get here, install them with your package manager"
        return 0
      fi
      local sudo=()
      [[ $EUID -ne 0 ]] && sudo=(sudo)
      if [[ ${#sudo[@]} -gt 0 ]] && ! have sudo; then
        warn "missing: ${missing[*]} -- no sudo, ask an admin to install them"
        return 0
      fi
      log "  apt-get install ${missing[*]} (may ask for your password)"
      run "${sudo[@]}" apt-get update -qq \
        && run "${sudo[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" \
        && ok "installed ${missing[*]}" \
        || warn "apt-get install failed: ${missing[*]}"
      ;;
    *)
      warn "missing: ${missing[*]} -- unknown OS, install them by hand"
      ;;
  esac
}

# link <source-in-repo> <dest-path>
# Idempotent. Backs up anything real that is in the way, replaces stale symlinks.
link() {
  local src="$1" dest="$2"
  [[ -e $src ]] || die "link: source missing: $src"
  own "$dest"

  if [[ -L $dest ]]; then
    local cur; cur="$(readlink "$dest")"
    if [[ $cur == "$src" ]]; then
      skip "$(prettify "$dest") already linked"
      return 0
    fi
    run rm -f "$dest"
  elif [[ -e $dest ]]; then
    run mkdir -p "$ME_BACKUP"
    local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
    run mv "$dest" "$ME_BACKUP/$(basename "$dest").$stamp"
    warn "backed up existing $(prettify "$dest") -> $ME_BACKUP/$(basename "$dest").$stamp"
  fi

  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  ok "$(prettify "$dest") -> $(prettify "$src")"
}

# Write $1 only if the content differs. Content comes from stdin.
#
# Use this directly for one-time stubs the user then edits (gitconfig.local,
# local.sh); those are never owned, so never pruned. For files the installer
# regenerates every run, use `generate`.
#
# Feed it with a redirect, not a pipe: `generate f < <(cmd)`. A pipe runs it in
# a subshell, which loses the ownership record and the change count.
write_if_changed() {
  local dest="$1" tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if [[ -f $dest ]] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    skip "$(prettify "$dest") unchanged"
    return 0
  fi
  if [[ $ME_DRY_RUN == 1 ]]; then
    printf '  %sdry-run:%s would write %s\n' "$_c_dim" "$_c_reset" "$dest"
    rm -f "$tmp"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
  ok "wrote $(prettify "$dest")"
}

prettify() { printf '%s' "${1/#$HOME/\~}"; }

# clone_pinned <label> <url> <ref> <dest>
#
# Clone a repo at an exact ref, or move an existing clone onto it. Used for
# things that are source rather than a release artifact: tmux plugins, firstmate.
clone_pinned() {
  local label="$1" url="$2" ref="$3" dest="$4"
  own "$dest"

  if [[ -d "$dest/.git" ]]; then
    if [[ "$(git -C "$dest" rev-parse HEAD 2>/dev/null)" == "$(git -C "$dest" rev-parse "$ref^{commit}" 2>/dev/null)" ]]; then
      skip "$label at $ref"
      return 0
    fi
    run git -C "$dest" fetch --quiet --tags origin
    run git -C "$dest" checkout --quiet --detach "$ref"
    ok "$label moved to $ref"
    return 0
  fi

  run mkdir -p "$(dirname "$dest")"
  run git clone --quiet "$url" "$dest" || { warn "$label: clone failed"; return 1; }
  run git -C "$dest" checkout --quiet --detach "$ref"
  ok "$label $ref -> $(prettify "$dest")"
}

# install_release_binary <name> <owner/repo> <tag>
#
# Fetch a single-binary GitHub release asset named <name>-<tag>-<os>-<arch>.tar.gz
# into ~/.<name>/bin and symlink it onto ~/.local/bin.
#
# Several of these tools ship a curl|sh installer that always resolves
# releases/latest -- there is no way to ask it for a specific version -- and
# falls back to `sudo` into /usr/local/bin whenever ~/.local/bin is not already
# on PATH. That is wrong for a pinned, unattended install on a fresh machine,
# so the asset is fetched directly. No sudo, ever.
install_release_binary() {
  local name="$1" repo="$2" tag="$3"
  local bin="$HOME/.$name/bin/$name"
  local dest="$HOME/.local/bin/$name"
  own "$HOME/.$name"
  own "$dest"

  if [[ -x $bin ]] && "$bin" --version 2>/dev/null | grep -qF "${tag#v}"; then
    skip "$name $tag already installed"
    return 0
  fi
  if [[ $ME_DRY_RUN == 1 ]]; then
    ok "dry run: would install $name $tag"
    return 0
  fi

  local arch os
  case "$(uname -m)" in
    x86_64|amd64)  arch=amd64 ;;
    arm64|aarch64) arch=arm64 ;;
    *) warn "$name: unsupported architecture $(uname -m)"; return 1 ;;
  esac
  [[ $(os_name) == macos ]] && os=darwin || os=linux

  local file="${name}-${tag}-${os}-${arch}.tar.gz"
  local url="https://github.com/${repo}/releases/download/${tag}/${file}"
  local tmp; tmp=$(mktemp -d)

  if curl -fsSL "$url" -o "$tmp/$file" && tar xzf "$tmp/$file" -C "$tmp"; then
    mkdir -p "$HOME/.$name/bin" "$HOME/.local/bin"
    install -m 0755 "$tmp/$name" "$bin"
    ln -sf "$bin" "$dest"
    ok "$name $tag -> $(prettify "$dest")"
    rm -rf "$tmp"
    return 0
  fi

  warn "$name: could not fetch $url"
  rm -rf "$tmp"
  return 1
}

# install_pi <tag>
#
# Pi's release tarball is a directory -- a self-contained binary plus themes,
# wasm and native modules it loads from beside itself -- not a single binary, so
# install_release_binary does not fit. Each version is unpacked to
# ~/.local/share/pi/<tag>, older versions are removed, and ~/.local/bin/pi is
# a two-line wrapper that execs the real binary in place.
install_pi() {
  local tag="$1"
  local root="$HOME/.local/share/pi"
  local bin="$root/$tag/pi"
  local dest="$HOME/.local/bin/pi"
  own "$root"
  own "$dest"

  if [[ -x $bin && -f $dest ]] && grep -qF "$bin" "$dest"; then
    skip "pi $tag already installed"
    return 0
  fi
  if [[ $ME_DRY_RUN == 1 ]]; then
    ok "dry run: would install pi $tag"
    return 0
  fi

  local arch os
  case "$(uname -m)" in
    x86_64|amd64)  arch=x64 ;;
    arm64|aarch64) arch=arm64 ;;
    *) warn "pi: unsupported architecture $(uname -m)"; return 1 ;;
  esac
  [[ $(os_name) == macos ]] && os=darwin || os=linux

  local file="pi-${os}-${arch}.tar.gz"
  local url="https://github.com/earendil-works/pi/releases/download/${tag}/${file}"
  local tmp; tmp=$(mktemp -d)

  log "  downloading pi $tag (~40 MB)"
  if curl -fsSL "$url" -o "$tmp/$file" && tar xzf "$tmp/$file" -C "$tmp" && [[ -x $tmp/pi/pi ]]; then
    rm -rf "${root:?}/$tag"
    mkdir -p "$root" "$HOME/.local/bin"
    mv "$tmp/pi" "$root/$tag"
    printf '#!/bin/sh\nexec "%s" "$@"\n' "$bin" > "$dest"
    chmod 0755 "$dest"
    local old
    for old in "$root"/*; do
      [[ $old == "$root/$tag" ]] || rm -rf "$old"
    done
    ok "pi $tag -> $(prettify "$dest")"
    rm -rf "$tmp"
    return 0
  fi

  warn "pi: could not fetch $url"
  rm -rf "$tmp"
  return 1
}

# --- desired state ------------------------------------------------------------
#
# Every path the installer manages is declared with `own` while its module runs
# (link, generate, clone_pinned and the tool installers all do this for you).
# At the end of a run, install.sh compares the declarations with the manifest
# from the previous run and removes whatever is no longer declared. So deleting
# a `link` line, a tool, or a whole module from this repo removes it from every
# machine on the next `me install` -- no cleanup code needed.
#
# Safety rules:
#   - Entries are grouped by module, or module/section once a module calls
#     `section`. A group's old entries are only pruned when that group ran in
#     full this time. --only/--skip, a `partial` group (skipped by --no-net or
#     --minimal) and a module that errors all leave their entries alone.
#   - A symlink is only removed if it still points into this repo. If you have
#     repointed it at something of your own, it is left in place.
#   - System packages (apt/brew) are never uninstalled.

ME_MANIFEST="$ME_STATE/state/managed.tsv"
ME_GROUP="core"
ME_OWNED=()      # "group<TAB>path" declared this run
ME_ENTERED=()    # groups the current module reached
ME_PARTIALS=()   # groups the current module skipped part of

# own <path>  -- declare that the current group manages <path>.
own() { ME_OWNED+=("$ME_GROUP"$'\t'"$1"); }

# section <name>  -- start a new group inside the current module. Put it before
# any early return that skips the section, so that skip can be marked partial
# without holding up pruning of the rest of the module.
section() { ME_GROUP="${ME_GROUP%%/*}/$1"; ME_ENTERED+=("$ME_GROUP"); }

# partial [why]  -- the current group skipped part of its work, so it did not
# declare everything it owns. Keep its previous entries instead of pruning.
partial() { ME_PARTIALS+=("$ME_GROUP"); [[ $# -eq 0 ]] || skip "$*"; }

# generate <dest>  -- a file the installer rewrites from the repo on every run.
# Owned, so it is removed again if the generate line is deleted.
generate() { own "$1"; write_if_changed "$1"; }

# retire <path>  -- remove a link this repo created before the manifest existed.
# Only acts on a symlink that points into this repo; safe to leave in forever.
retire() {
  local p="$1"
  [[ -L $p ]] || return 0
  case "$(readlink "$p")" in
    "$ME_ROOT"/*|"$ME_ROOT"|"$ME_STATE/root"/*) ;;
    *) return 0 ;;
  esac
  run rm -f "$p"
  ok "removed retired $(prettify "$p")"
}

# _prune <path>  -- remove one path that is no longer declared.
_prune() {
  local p="$1"
  # Never anything outside $HOME, $HOME itself, or the user's own state files.
  case "$p" in
    "$HOME"/?*) ;;
    *) warn "not pruning $p: outside \$HOME"; return 0 ;;
  esac
  case "$p" in
    "$ME_STATE/secrets.env"|"$ME_STATE/local.sh"|"$ME_STATE"/*.local*) return 0 ;;
  esac

  if [[ -L $p ]]; then
    case "$(readlink "$p")" in
      "$ME_ROOT"/*|"$ME_ROOT"|"$ME_STATE/root"/*|"$ME_STATE/root") ;;
      *) skip "$(prettify "$p") no longer managed, but now points elsewhere -- leaving it"; return 0 ;;
    esac
    run rm -f "$p"
  elif [[ -e $p ]]; then
    run rm -rf "$p"
  else
    return 0
  fi
  ok "removed $(prettify "$p") (no longer in this repo)"
}

# reconcile <module>...  -- the modules that ran in full this time.
# Prunes their stale entries and writes the new manifest. Plain awk rather than
# associative arrays, so it runs on macOS's stock bash 3.2.
reconcile() {
  local full; full=",$(IFS=,; echo "$*"),"
  local tmp; tmp=$(mktemp -d)
  local prev="$tmp/prev" cur="$tmp/cur"

  if [[ -f $ME_MANIFEST ]]; then cp "$ME_MANIFEST" "$prev"; else : > "$prev"; fi
  # ${a[@]+...}: an empty array is "unbound" under set -u in bash 3.2.
  printf '%s\n' ${ME_OWNED[@]+"${ME_OWNED[@]}"} | awk 'NF' > "$cur"

  # kept  = previous entries of modules that did not run in full
  # next  = this run's entries + kept
  # prune = previous entries of full modules whose path nothing declares now
  awk -F'\t' -v full="$full" -v dir="$tmp" '
    FNR == NR { want[$2] = 1; print > (dir "/next"); next }
    NF < 2    { next }
    index(full, "," $1 ",") == 0 { print > (dir "/next"); want[$2] = 1; next }
              { stale[$2] = 1 }
    END {
      for (p in stale) if (!(p in want)) print p > (dir "/prune")
    }' "$cur" "$prev"

  local p
  if [[ -f $tmp/prune ]]; then
    while IFS= read -r p; do _prune "$p"; done < <(sort "$tmp/prune")
  fi

  if [[ $ME_DRY_RUN != 1 ]]; then
    mkdir -p "$(dirname "$ME_MANIFEST")"
    touch "$tmp/next"
    sort -u "$tmp/next" > "$ME_MANIFEST.tmp" && mv "$ME_MANIFEST.tmp" "$ME_MANIFEST"
  fi
  rm -rf "$tmp"
}
