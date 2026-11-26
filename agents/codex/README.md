# Codex

`~/.codex/config.toml` is rewritten by Codex itself. It stores per-project trust
levels, plugin state and marketplace metadata. Symlinking it into this repo would
mean fighting the tool on every write, so it is left alone.

What this repo *does* manage:

- `~/.codex/AGENTS.md` → symlink to `agents/AGENTS.md`. Codex reads this as its
  global instruction file.

- `~/.codex/brendank.config.toml` is linked to [`brendank.config.toml`](brendank.config.toml).
  Edit that file to change the CLI model, approval settings, or `me-dev`
  permissions. Its workspace paths are specific to Brendan's checkout.

The Bash aliases `cx` and `cxr` select the `brendank` profile when it is
installed. Use `cx` to start Codex and `cxr` to resume the last session. In a
script, use `codex --profile brendank` explicitly. The desktop app reads its
usual settings from `~/.codex/config.toml`.
