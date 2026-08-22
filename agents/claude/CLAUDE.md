@$HOME/.config/me/AGENTS.md

# Claude Code specifics

The rules above are shared across every harness. Anything below is Claude-only.

- Prefer the built-in file tools over shelling out to `cat`/`sed` for edits;
  the diffs are reviewable and the harness tracks the file state.
- `/code-review` before pushing anything non-trivial.
