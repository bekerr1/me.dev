# Codex

`~/.codex/config.toml` is rewritten by Codex itself. It stores per-project trust
levels, plugin state and marketplace metadata. Symlinking it into this repo would
mean fighting the tool on every write, so it is left alone.

What this repo *does* manage:

- `~/.codex/AGENTS.md` → symlink to `agents/AGENTS.md`. Codex reads this as its
  global instruction file.

Settings worth applying by hand once per machine (`codex` reads them from
`config.toml`):

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "xhigh"
```
