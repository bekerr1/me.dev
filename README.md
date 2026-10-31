# me

One repo for the whole development environment: shell, git, tmux, neovim, and
the agent harness configuration. Clone it on any machine (macOS, Linux, or a box you only ever reach over ssh),
run one command, and be productive.

```bash
git clone <this-repo> ~/Development/me && ~/Development/me/install.sh
```

A fresh Ubuntu install has neither `git` nor `curl`. The installer adds `curl`
itself, but you need `git` to clone, so on a brand-new machine start with:

```bash
sudo apt install -y git
```

Everything is symlinked back to the checkout, so `git pull` updates the live
config. Nothing is copied except the two machine-local files that must not be
tracked.

## Install

| Command | What it does |
| --- | --- |
| `./install.sh` | Everything: system packages (curl, git, Ghostty), shell, git, tmux, neovim, agent instructions and all agent tooling |
| `./install.sh --minimal` | curl and git, then shell, git, tmux only, for servers and jump boxes. No Ghostty. |
| `./install.sh --only nvim` | One module |
| `./install.sh --no-net` | Relink config, download nothing |
| `./install.sh --dry-run` | Show what would change |

Re-running is always safe. Anything real that is in the way moves to
`~/.me-backup/` first.

### Desired state

The installer is declarative: each run converges the machine on what the repo
describes, then reports `N change(s)` or `already up to date`. Add something
and it gets installed; delete it from the repo and the next `me install` (or
`me sync`) removes it from the machine. Nothing needs a matching cleanup step.

This works through a manifest at `~/.config/me/state/managed.tsv`. Every path the
installer manages is recorded against its module, and anything recorded last
time but not declared this time is pruned. `link`, `generate`, `clone_pinned`,
`install_release_binary` and `install_pi` all record their paths automatically.

Pruning is deliberately conservative:

- `--only` and `--skip` never prune modules they did not run.
- A module that errors keeps everything it had.
- A section a module skips (downloads under `--no-net`, desktop apps under
  `--minimal`) is marked `partial` and keeps its old entries. The rest of the
  module still reconciles.
- A symlink you have repointed somewhere else is left alone.
- System packages are never uninstalled.

To add to it:

| You want | Write, in an `install.d/*.sh` module |
| --- | --- |
| A config file or directory from the repo | `link "$ME_ROOT/x" "$HOME/.x"` |
| A file built from repo content | `generate "$HOME/.x" < <(cmd)`, a redirect rather than a pipe |
| A one-time stub the user edits (never pruned) | `write_if_changed "$ME_STATE/x" <<'EOF'` only if the file is missing |
| A git repo at a fixed ref | `clone_pinned` with the pin in `tools.env` |
| A single-binary GitHub release | `install_release_binary` with the pin in `tools.env` |
| Anything else the installer creates | `own "$path"`, then create it idempotently |
| A part a flag can skip | `section <name>` before it, `partial "why"` in the skip branch |
| A whole new module | add `install.d/<name>.sh` and list it in `MODULES` in `install.sh` |
| Clean up a link made before the manifest existed | `retire "$HOME/.x"` |

`me install --dry-run` shows exactly what a run would add and remove.

Neovim plugins reconcile the same way. The installer installs anything missing
from the spec and removes anything no longer in it, but never updates plugins:
use `:Lazy update` for that.

### System packages

`install.d/packages.sh` runs first and installs what has to come from the OS
package manager: `curl`, `git` and `tmux` everywhere, plus Neovim, ripgrep,
fzf and [Ghostty](https://ghostty.org), the default terminal, unless
`--minimal` is set.
It uses `apt-get` on Linux and Homebrew on macOS. This is the only module that
runs `sudo`, and only when something is missing, so re-runs never prompt.
`--no-net` reports what is missing but installs nothing.

On Linux it also makes Ghostty the default terminal (Ctrl+Alt+T, "Open in
Terminal") by writing `~/.config/xdg-terminals.list`.

## Terminal colors

`ghostty/config.ghostty` is linked to `~/.config/ghostty/config.ghostty`. It uses
Ghostty's built-in Cursor Dark theme. (nvim and the tmux status bar still use
kanagawa-dragon.) To change a color, uncomment its line in
the overrides block (every value the theme sets is listed there) and press
`ctrl+shift+,` in Ghostty to reload. `ghostty +list-themes` previews the other
built-in themes; swap the `theme =` line to use one.

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
install.d/packages.sh  OS packages (curl, git, tmux, neovim, ...); the only module that uses sudo
lib/common.sh       symlink/backup/logging helpers
tools.env           pinned versions of everything fetched from the network

shell/              bashrc + bash_profile loaders; rc.d/*.sh is the real config
git/                gitconfig, global ignore, and the minimal commit editor
tmux/               tmux.conf + conf.d/{options,keys,status,nested,persist}
nvim/               lean neovim: 8 plugins, no LSP
ghostty/            terminal config: Cursor Dark colors
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
  Sessions survive reboots: tmux-continuum saves every 15 minutes, `C-e C-s`
  saves now and `C-e C-r` restores.
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
| Pi | `~/.pi/agent/AGENTS.md` |

Edit `agents/AGENTS.md` and run `me sync`. Never edit the copies.

Third-party tooling, pinned in `tools.env`. `me pins` reports what has moved
upstream; bump the pin and re-run `me install`.

All of it installs on every machine, no flags. `--minimal` and `--no-net` skip
the lot, which is what you want on a server or a jump box.

| Tool | Lands in | Purpose |
| --- | --- | --- |
| [mattpocock/skills](https://github.com/mattpocock/skills) | `~/.agents/skills`, symlinked into each harness | 36 engineering skills: `/implement`, `/tdd`, `/to-spec`, `/code-review` |
| [firstmate](https://github.com/kunchenguid/firstmate) | `~/.local/share/firstmate` | Agent swarms: one first mate dispatching a crew across git worktrees. Launch with `fm`. |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `~/.local/bin/no-mistakes` | Validation pipeline in front of `git push`. Run `no-mistakes init` per repo. |
| [treehouse](https://github.com/kunchenguid/treehouse) | `~/.local/bin/treehouse` | Git worktree management |
| [Pi](https://github.com/earendil-works/pi) | `~/.local/share/pi/<version>`, launcher at `~/.local/bin/pi` | Minimal, extensible agent harness. Picks up `~/.agents/skills` on its own. Run `/login` inside it once. |

Two notes on how these are installed:

- `skills` writes `skills-lock.json` into the working directory, so it is run
  from `$HOME`, so the lock is global, not per-repo, and never lands in this repo.
- `no-mistakes` and `treehouse` both ship a `curl | sh` installer that always
  takes `releases/latest`, with no way to request a version, and falls back to
  `sudo` into `/usr/local/bin` when `~/.local/bin` is not already on `PATH`.
  Neither suits a pinned, unattended install on a fresh machine, so
  `install_release_binary` in `lib/common.sh` fetches the release asset directly.
  No sudo.
- Pi's own installer is interactive and installs Node first. Pi also ships a
  self-contained binary per platform, so `install_pi` unpacks that release
  instead: no Node needed. Update it by bumping `PI_VERSION`, not `pi update`.
