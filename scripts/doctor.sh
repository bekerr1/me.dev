#!/usr/bin/env bash
# Verify the install actually took. Exits non-zero if anything is broken.

set -uo pipefail
ME_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ME_STATE="$HOME/.config/me"
fails=0

if [[ -t 1 ]]; then G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; D=$'\033[2m'; N=$'\033[0m'
else G=; R=; Y=; D=; N=; fi

pass() { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
fail() { printf '  %s✗%s %s\n' "$R" "$N" "$*"; fails=$((fails+1)); }
note() { printf '  %s·%s %s\n' "$D" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
section() { printf '\n%s\n' "$*"; }

check_link() {
  local dest="$1" want="$2"
  if [[ -L $dest && "$(readlink "$dest")" == "$want" ]]; then
    pass "${dest/#$HOME/\~}"
  elif [[ -e $dest ]]; then
    fail "${dest/#$HOME/\~} exists but is not our symlink"
  else
    fail "${dest/#$HOME/\~} is missing"
  fi
}

section "links"
check_link "$ME_STATE/root" "$ME_ROOT"
check_link "$HOME/.bashrc" "$ME_ROOT/shell/bashrc"
check_link "$HOME/.bash_profile" "$ME_ROOT/shell/bash_profile"
check_link "$HOME/.gitconfig" "$ME_ROOT/git/gitconfig"
check_link "$HOME/.tmux.conf" "$ME_ROOT/tmux/tmux.conf"
check_link "$HOME/.config/nvim" "$ME_ROOT/nvim"
check_link "$HOME/.config/ghostty/config.ghostty" "$ME_ROOT/ghostty/config.ghostty"
check_link "$ME_STATE/AGENTS.md" "$ME_ROOT/agents/AGENTS.md"
check_link "$HOME/.claude/CLAUDE.md" "$ME_ROOT/agents/claude/CLAUDE.md"
check_link "$HOME/.pi/agent/AGENTS.md" "$ME_ROOT/agents/AGENTS.md"

section "tools"
for t in bash curl git tmux nvim rg; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t  $(command -v "$t")"; else fail "$t not found"; fi
done
for t in gh fzf claude codex pi node ghostty go gopls cargo rust-analyzer cmake ninja; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t  $(command -v "$t")"; else note "$t not found (optional)"; fi
done

section "config parses"
if bash -n "$ME_ROOT/shell/bashrc" 2>/dev/null; then pass "bashrc"; else fail "bashrc has a syntax error"; fi
for f in "$ME_ROOT"/shell/rc.d/*.sh; do
  bash -n "$f" 2>/dev/null || fail "syntax error in ${f##*/}"
done
if command -v tmux >/dev/null 2>&1; then
  out=$(tmux -L me-doctor -f /dev/null start-server \; source-file "$HOME/.tmux.conf" 2>&1)
  tmux -L me-doctor kill-server 2>/dev/null
  if [[ -z $out ]]; then pass "tmux.conf"; else fail "tmux.conf: $out"; fi
fi
if command -v nvim >/dev/null 2>&1; then
  if nvim --headless "+lua vim.cmd('quit')" +qa >/dev/null 2>&1; then pass "nvim starts clean"
  else fail "nvim reported errors on startup -- run: nvim --headless +qa"; fi
fi

section "managed"
manifest="$ME_STATE/state/managed.tsv"
if [[ -f $manifest ]]; then
  missing=0 total=0
  while IFS=$'\t' read -r mod path; do
    [[ -n $path ]] || continue
    total=$((total + 1))
    if [[ ! -e $path && ! -L $path ]]; then
      fail "${path/#$HOME/\~} ($mod) is in the manifest but missing -- run: me install"
      missing=$((missing + 1))
    fi
  done < "$manifest"
  [[ $missing -eq 0 ]] && pass "all $total managed paths present"
else
  warn "no manifest yet -- run: me install"
fi

section "secrets"
if [[ -f "$ME_STATE/secrets.env" ]]; then
  perms=$(stat -c '%a' "$ME_STATE/secrets.env" 2>/dev/null || stat -f '%Lp' "$ME_STATE/secrets.env")
  [[ $perms == 600 ]] && pass "secrets.env mode $perms" || fail "secrets.env is mode $perms, should be 600"
else
  warn "no secrets.env yet"
fi
if git -C "$ME_ROOT" ls-files --error-unmatch 'shell/secrets.env' >/dev/null 2>&1; then
  fail "secrets.env is TRACKED BY GIT -- remove it from the index now"
else
  pass "no secrets.env in the index"
fi

printf '\n'
if [[ $fails -eq 0 ]]; then printf '%sall good%s\n' "$G" "$N"; else printf '%s%d problem(s)%s\n' "$R" "$fails" "$N"; fi
exit $((fails > 0))
