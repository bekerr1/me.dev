#!/usr/bin/env bash
#
# me -- one-shot development environment install.
#
#   ./install.sh                     everything, including the agent tooling
#   ./install.sh --minimal           shell, git, tmux only (servers, ssh boxes)
#   ./install.sh --only nvim,tmux    just those modules
#   ./install.sh --skip agents
#   ./install.sh --no-net            relink config only, no downloads
#   ./install.sh --dry-run
#
# Idempotent: safe to re-run after every `git pull`. Anything real that is in
# the way gets moved to ~/.me-backup rather than deleted.

set -euo pipefail

ME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ME_ROOT
. "$ME_ROOT/lib/common.sh"

MODULES=(shell git tmux nvim agents)
ONLY=""
SKIP=""

usage() { sed -n '2,20p' "$0" | sed 's/^#\ \?//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal)  ME_MINIMAL=1; ONLY="shell,git,tmux"; shift ;;
    --only)     ONLY="${2:?--only needs a list}"; shift 2 ;;
    --skip)     SKIP="${2:?--skip needs a list}"; shift 2 ;;
    --no-net)   ME_NO_NET=1; shift ;;
    --dry-run)  ME_DRY_RUN=1; shift ;;
    -h|--help)  usage ;;
    *)          die "unknown option: $1 (try --help)" ;;
  esac
done
ME_NO_NET="${ME_NO_NET:-0}"
export ME_MINIMAL ME_DRY_RUN ME_NO_NET

in_list() { case ",$2," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

selected() {
  [[ -n $ONLY ]] && { in_list "$1" "$ONLY" || return 1; }
  [[ -n $SKIP ]] && { in_list "$1" "$SKIP" && return 1; }
  return 0
}

log "me -- $(os_name), $(prettify "$ME_ROOT")"
[[ $ME_DRY_RUN == 1 ]] && warn "dry run: nothing will be written"

# Every consumer (tmux.conf, .bashrc, gitconfig) refers to the repo through this
# one stable path, so the checkout can live anywhere.
run mkdir -p "$ME_STATE"
link "$ME_ROOT" "$ME_STATE/root"

for m in "${MODULES[@]}"; do
  selected "$m" || { skip "module $m (filtered out)"; continue; }
  script="$ME_ROOT/install.d/$m.sh"
  [[ -r $script ]] || die "missing module: $script"
  log "$m"
  # A module ending in a false-y test (`have foo && ...`) would otherwise abort
  # the whole install under `set -e`. Modules signal real failures with die().
  # shellcheck disable=SC1090
  . "$script" || true
done

log "done"
if [[ ! -f "$ME_STATE/secrets.env" ]]; then
  warn "no $(prettify "$ME_STATE/secrets.env") yet -- copy secrets.env.example and fill it in"
fi
printf '\nRestart your shell, or: %sexec bash -l%s\n' "$_c_grn" "$_c_reset"
