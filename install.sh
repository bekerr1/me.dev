#!/usr/bin/env bash
#
# me -- one-shot development environment install.
#
#   ./install.sh                     everything, including the agent tooling and ghostty
#   ./install.sh --minimal           curl/git, shell, git config, tmux only (servers, ssh boxes)
#   ./install.sh --only nvim,tmux    just those modules
#   ./install.sh --skip agents
#   ./install.sh --no-net            relink config only, no downloads
#   ./install.sh --dry-run
#
# Declarative: re-running converges the machine on what this repo describes.
# Things added to the repo get installed; things removed from it get removed
# (see "desired state" in lib/common.sh). Anything real that is in the way gets
# moved to ~/.me-backup rather than deleted.

set -euo pipefail

ME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ME_ROOT
. "$ME_ROOT/lib/common.sh"

MODULES=(packages shell git tmux nvim agents)
ONLY=""
SKIP=""

usage() { awk 'NR>1 && !/^#/ {exit} NR>1 {sub(/^# ?/, ""); print}' "$0"; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal)  ME_MINIMAL=1; ONLY="packages,shell,git,tmux"; shift ;;
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
[[ $ME_DRY_RUN == 1 ]] && info "dry run: nothing will be written"

# Every consumer (tmux.conf, .bashrc, gitconfig) refers to the repo through this
# one stable path, so the checkout can live anywhere.
run mkdir -p "$ME_STATE"
link "$ME_ROOT" "$ME_STATE/root"
FULL=(core)   # groups that ran in full, so their stale entries can be pruned

# Groups the previous run recorded, for spotting sections and modules that have
# since been deleted from the repo.
OLD_GROUPS=()
[[ -f $ME_MANIFEST ]] && while IFS= read -r g; do OLD_GROUPS+=("$g"); done \
  < <(cut -f1 "$ME_MANIFEST" | sort -u)

for m in "${MODULES[@]}"; do
  selected "$m" || { skip "module $m (filtered out)"; continue; }
  script="$ME_ROOT/install.d/$m.sh"
  [[ -r $script ]] || die "missing module: $script"
  log "$m"
  ME_GROUP="$m"; ME_ENTERED=("$m"); ME_PARTIALS=()
  # A module ending in a false-y test (`have foo && ...`) would otherwise abort
  # the whole install under `set -e`. Modules signal real failures with die().
  # A module that returns non-zero keeps all of its old entries: an incomplete
  # run is no evidence that anything was removed.
  # shellcheck disable=SC1090
  . "$script" || { skip "$m returned an error; not pruning its entries"; continue; }
  partials=",$(IFS=,; echo "${ME_PARTIALS[*]-}"),"
  for g in "${ME_ENTERED[@]}"; do
    in_list "$g" "$partials" || FULL+=("$g")
  done
  # A clean module no longer owns sections it did not reach, i.e. ones that
  # were deleted from it.
  if [[ ${#ME_PARTIALS[@]} -eq 0 ]]; then
    for g in ${OLD_GROUPS[@]+"${OLD_GROUPS[@]}"}; do
      [[ $g == "$m/"* ]] && FULL+=("$g")
    done
  fi
done

# A module deleted from MODULES owns nothing any more. Only conclude that on an
# unfiltered run, so `--only nvim` never prunes the rest of the machine.
if [[ -z $ONLY && -z $SKIP ]]; then
  for g in ${OLD_GROUPS[@]+"${OLD_GROUPS[@]}"}; do
    in_list "${g%%/*}" "core,$(IFS=,; echo "${MODULES[*]}")" || FULL+=("$g")
  done
fi

log "reconcile"
reconcile "${FULL[@]}"

log "done"
if [[ $ME_DRY_RUN == 1 ]]; then
  info "dry run: $ME_CHANGES change(s) would be made, $ME_WARNINGS warning(s)"
elif [[ $ME_CHANGES -eq 0 ]]; then
  info "already up to date ($ME_WARNINGS warning(s))"
else
  info "$ME_CHANGES change(s), $ME_WARNINGS warning(s)"
fi
if [[ ! -f "$ME_STATE/secrets.env" ]]; then
  warn "no $(prettify "$ME_STATE/secrets.env") yet -- copy secrets.env.example and fill it in"
fi
printf '\nRestart your shell, or: %sexec bash -l%s\n' "$_c_grn" "$_c_reset"
