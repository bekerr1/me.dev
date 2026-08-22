# me

One repo for the whole development environment: shell, git, tmux, neovim, and
the agent harness configuration. Clone it on any machine — macOS, Linux, a box
you only ever reach over ssh — run one command, and be productive.

```bash
git clone <this-repo> ~/Development/me && ~/Development/me/install.sh
```

Everything is symlinked back to the checkout, so `git pull` updates the live
config. Nothing is copied except the two machine-local files that must not be
tracked.

## Install

| Command | What it does |
| --- | --- |
| `./install.sh` | Everything: shell, git, tmux, neovim, agent instructions and all agent tooling |
| `./install.sh --minimal` | Shell, git, tmux only — for servers and jump boxes |
| `./install.sh --only nvim` | One module |
| `./install.sh --no-net` | Relink config, download nothing |
| `./install.sh --dry-run` | Show what would change |

Re-running is always safe. Anything real that is in the way moves to
`~/.me-backup/` first.

After install, `me` is on `$PATH`:

```
me install    re-run the installer
me update     git pull, then reinstall
me sync       relink config only, no network
me doctor     verify everything is wired up
me pins       report which pinned upstreams have moved
me edit       open this repo in nvim
```

## What lives where

```
install.sh          entry point; install.d/*.sh are the modules
lib/common.sh       symlink/backup/logging helpers
tools.env           pinned versions of everything fetched from the network

shell/              bashrc + bash_profile loaders; rc.d/*.sh is the real config
git/                gitconfig, global ignore, and the minimal commit editor
tmux/               tmux.conf + conf.d/{options,keys,status,nested}
nvim/               lean neovim: 8 plugins, no LSP
agents/             AGENTS.md and the per-harness wiring
bin/me              the CLI
scripts/            doctor, pin checker, pre-commit secret guard
docs/               keybinding reference, migration notes
```

Two files are **not** tracked and live in `~/.config/me/`:

| File | For |
| --- | --- |
| `secrets.env` | API keys and tokens. Mode 600, sourced by `.bashrc`. |
| `local.sh` | Host-specific PATH, tool init, one-off aliases. |
| `gitconfig.local` | Git identity. |
| `tmux.local.conf` | Host-specific tmux tweaks. |

The repo is reachable from a stable path at `~/.config/me/root`, which is how
`.bashrc`, `tmux.conf` and `gitconfig` find their fragments regardless of where
the checkout actually lives.

## Secrets

Credentials never enter this repo. `secrets.env.example` lists the variable
names; the real file is created by the installer and gitignored.

A pre-commit hook that blocks key-shaped strings ships in `scripts/pre-commit`.
Enable it with:

```bash
git config core.hooksPath scripts
```

## Keybindings

Full reference in [`docs/keybindings.md`](docs/keybindings.md). The three that
matter most:

- **tmux prefix is `C-e`.** `C-e t` new named window, `C-e T` new window at a
  chosen index, `C-e C-e` last window, `F12` hands control to a nested tmux.
- **neovim `J` / `K`** travel 15 lines and recentre. `C-n` toggles the file tree.
- **`git commit`** opens a plugin-free nvim (`git/editor.vim`), not the full config.

## Agents

`agents/AGENTS.md` is the single source of truth for agent behaviour. The
installer symlinks it into every harness:

| Harness | Path |
| --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` (imports it) |
| Codex | `~/.codex/AGENTS.md` |
| Cursor | `~/.cursor/rules/agents.mdc` (generated) |
| Pi and others | `~/AGENTS.md` |

Edit `agents/AGENTS.md` and run `me sync`. Never edit the copies.

Third-party tooling, pinned in `tools.env`. `me pins` reports what has moved
upstream; bump the pin and re-run `me install`.

All of it installs on every machine — no flags. `--minimal` and `--no-net` skip
the lot, which is what you want on a server or a jump box.

| Tool | Lands in | Purpose |
| --- | --- | --- |
| [mattpocock/skills](https://github.com/mattpocock/skills) | `~/.agents/skills`, symlinked into each harness | 36 engineering skills — `/implement`, `/tdd`, `/to-spec`, `/code-review` |
| [firstmate](https://github.com/kunchenguid/firstmate) | `~/.local/share/firstmate` | Agent swarms — one first mate dispatching a crew across git worktrees. Launch with `fm`. |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `~/.local/bin/no-mistakes` | Validation pipeline in front of `git push`. Run `no-mistakes init` per repo. |
| [treehouse](https://github.com/kunchenguid/treehouse) | `~/.local/bin/treehouse` | Git worktree management |

Two notes on how these are installed:

- `skills` writes `skills-lock.json` into the working directory, so it is run
  from `$HOME` — the lock is global, not per-repo, and never lands in this repo.
- `no-mistakes` and `treehouse` both ship a `curl | sh` installer that always
  takes `releases/latest`, with no way to request a version, and falls back to
  `sudo` into `/usr/local/bin` when `~/.local/bin` is not already on `PATH`.
  Neither suits a pinned, unattended install on a fresh machine, so
  `install_release_binary` in `lib/common.sh` fetches the release asset directly.
  No sudo.
