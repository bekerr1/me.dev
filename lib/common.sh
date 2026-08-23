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

log()  { printf '%s==>%s %s\n' "$_c_blu" "$_c_reset" "$*"; }
ok()   { printf '  %s✓%s %s\n'  "$_c_grn" "$_c_reset" "$*"; }
skip() { printf '  %s·%s %s\n'  "$_c_dim" "$_c_reset" "$*"; }
warn() { printf '  %s!%s %s\n'  "$_c_ylw" "$_c_reset" "$*" >&2; }
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

# link <source-in-repo> <dest-path>
# Idempotent. Backs up anything real that is in the way, replaces stale symlinks.
link() {
  local src="$1" dest="$2"
  [[ -e $src ]] || die "link: source missing: $src"

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

# Write $2 to file $1 only if the content differs. Content comes from stdin.
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

  if [[ -x $bin ]] && "$bin" --version 2>/dev/null | grep -qF "${tag#v}"; then
    skip "$name $tag already installed"
    return 0
  fi
  if [[ $ME_DRY_RUN == 1 ]]; then
    skip "dry run: would install $name $tag"
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
