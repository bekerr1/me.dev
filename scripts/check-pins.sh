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

openvsx() {
  curl -fsS "https://open-vsx.org/api/$1" 2>/dev/null \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["version"])' 2>/dev/null
}
check vscode-neovim "$VSCODE_NEOVIM_VERSION" "$(openvsx asvetliakov/vscode-neovim)"
check vscode-clangd "$VSCODE_CLANGD_VERSION" "$(openvsx llvm-vs-code-extensions/vscode-clangd)"
check vscode-go "$VSCODE_GO_VERSION" "$(openvsx golang/Go)"

latest_rustup=$(curl -fsS https://static.rust-lang.org/rustup/release-stable.toml 2>/dev/null \
  | sed -n "s/^version = '\(.*\)'/\1/p")
check rustup "$RUSTUP_VERSION" "$latest_rustup"
latest_rust=$(curl -fsS https://static.rust-lang.org/dist/channel-rust-stable.toml 2>/dev/null \
  | sed -n '/^\[pkg.rust\]/{n;s/^version = "\([^ ]*\).*/\1/p;}')
check rust "$RUST_VERSION" "$latest_rust"

check kubectl "$KUBECTL_VERSION" "$(curl -fsS https://dl.k8s.io/release/stable.txt 2>/dev/null)"

if command -v gh >/dev/null 2>&1; then
  latest_fm=$(gh api repos/kunchenguid/firstmate/commits/main --jq '.sha' 2>/dev/null | cut -c1-12)
  check firstmate "$FIRSTMATE_REF" "$latest_fm"

  latest_nm=$(gh api repos/kunchenguid/no-mistakes/releases/latest --jq '.tag_name' 2>/dev/null)
  check no-mistakes "$NO_MISTAKES_VERSION" "$latest_nm"

  latest_th=$(gh api repos/kunchenguid/treehouse/releases/latest --jq '.tag_name' 2>/dev/null)
  check treehouse "$TREEHOUSE_VERSION" "$latest_th"

  latest_pi=$(gh api repos/earendil-works/pi/releases/latest --jq '.tag_name' 2>/dev/null)
  check pi "$PI_VERSION" "$latest_pi"

  latest_helm=$(gh api repos/helm/helm/releases/latest --jq '.tag_name' 2>/dev/null)
  check helm "$HELM_VERSION" "$latest_helm"

  latest_kind=$(gh api repos/kubernetes-sigs/kind/releases/latest --jq '.tag_name' 2>/dev/null)
  check kind "$KIND_VERSION" "$latest_kind"

  latest_docker=$(gh api repos/moby/moby/releases/latest --jq '.tag_name' 2>/dev/null)
  check docker "${DOCKER_VERSION#v}" "${latest_docker#docker-v}"
else
  echo "gh not installed -- skipping the GitHub-hosted pins"
fi

printf '\nEdit %s/tools.env to bump, then: me install\n' "$ME_ROOT"
