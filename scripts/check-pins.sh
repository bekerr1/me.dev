#!/usr/bin/env bash
# Report where tools.env pins sit relative to upstream. Read-only; bump by hand.

set -uo pipefail
ME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ME_ROOT/tools.env"

row() { printf '%-16s %-14s %-14s %s\n' "$1" "$2" "$3" "$4"; }
row TOOL PINNED LATEST STATUS
row ---- ------ ------ ------

check() {
  local name="$1" pinned="$2" latest="$3"
  if [[ -z $latest ]]; then
    row "$name" "$pinned" "?" "could not reach upstream"
  elif [[ $pinned == "$latest" ]]; then
    row "$name" "$pinned" "$latest" "current"
  else
    row "$name" "$pinned" "$latest" "UPDATE AVAILABLE"
  fi
}

latest_npm=$(curl -fsS https://registry.npmjs.org/skills 2>/dev/null \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["dist-tags"]["latest"])' 2>/dev/null)
check skills "$SKILLS_NPM_VERSION" "$latest_npm"

if command -v gh >/dev/null 2>&1; then
  latest_fm=$(gh api repos/kunchenguid/firstmate/commits/main --jq '.sha' 2>/dev/null | cut -c1-12)
  check firstmate "$FIRSTMATE_REF" "$latest_fm"

  latest_nm=$(gh api repos/kunchenguid/no-mistakes/releases/latest --jq '.tag_name' 2>/dev/null)
  check no-mistakes "$NO_MISTAKES_VERSION" "$latest_nm"

  latest_th=$(gh api repos/kunchenguid/treehouse/releases/latest --jq '.tag_name' 2>/dev/null)
  check treehouse "$TREEHOUSE_VERSION" "$latest_th"
else
  echo "gh not installed -- skipping the GitHub-hosted pins"
fi

printf '\nEdit %s/tools.env to bump, then: me install\n' "$ME_ROOT"
