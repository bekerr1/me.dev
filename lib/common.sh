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
