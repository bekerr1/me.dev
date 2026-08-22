# Coding agents. The harnesses are the primary interface now, so these get real
# estate that the old cloud-vendor aliases used to occupy.

alias cc='claude'
alias ccc='claude --continue'
alias ccr='claude --resume'
alias cx='codex'
alias cxr='codex resume --last'

# Every harness reads the same instruction file. See agents/AGENTS.md.
export ME_AGENTS_FILE="$HOME/.config/me/AGENTS.md"

# Open the shared agent instructions.
agents() { nvim "$ME_AGENTS_FILE"; }

# fm -- launch firstmate's first mate in the current repo using the configured
# harness. Installed only when `me install --with firstmate` was run.
fm() {
  local dir="${FIRSTMATE_HOME:-$HOME/.local/share/firstmate}"
  if [ ! -d "$dir" ]; then
    printf 'firstmate is not installed. Run: me install --with firstmate\n' >&2
    return 1
  fi
  ( cd "$dir" && "${FIRSTMATE_HARNESS:-claude}" "$@" )
}
