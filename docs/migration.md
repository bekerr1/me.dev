# Migration from `dot-files`

The old repo is at `~/dot-files`. Nothing there was deleted — it is still a git
repo, so anything dropped here is one `git show` away.

## Kept

| Thing | Where it went | Notes |
| --- | --- | --- |
| `AGENTS.md` | `agents/AGENTS.md` | Verbatim, plus a secrets clause in §5 |
| tmux prefix `C-e` | `tmux/conf.d/10-keys.conf` | Unchanged |
| `C-e t` / `C-e T` window creation | same | `T` now uses `-b`, so an index that is already taken inserts and shifts instead of failing with "index in use". Indices past the end still create a gap, as before. |
| Stable window indices | `tmux/conf.d/00-options.conf` | `renumber-windows` left off and no `move-window -r`, so a window put at index 6 stays at 6 |
| Session-per-project helpers | `shell/rc.d/50-tmux.sh` | `tms` now attaches if the session exists, and works from inside tmux |
| nvim `J`/`K` = 15 lines | `nvim/lua/me/config/keymaps.lua` | Unchanged, now also in visual mode |
| `C-n` file tree | `nvim/lua/me/plugins/tree.lua` | Unchanged |
| kanagawa-dragon | `nvim/lua/me/plugins/colorscheme.lua` | Now also drives the tmux palette |
| lualine | `nvim/lua/me/plugins/lualine.lua` | Rewritten; the old config had its `sections` nested inside `options`, so most of it never applied |
| Black-hole deletes, `v p` yank-paste | keymaps | Unchanged |
| Per-filetype indentation | `nvim/lua/me/config/autocmds.lua` | Same values, table-driven |
| VS Code / Cursor keymaps | `nvim/lua/me/config/vscode.lua` | Minus the hardcoded chat-panel UUID |
| `ll`, `pbcopy`/`pbpaste`, `untils`, `+x`, CSV formatter | `shell/rc.d/30-aliases.sh` | `format`/`formatev` merged into `csv` |
| Git aliases you actually use | `shell/rc.d/40-git.sh` | `pullmaster` → `pullmain`, now branch-name agnostic |
| Prompt shape `[host] path $` | `shell/rc.d/20-prompt.sh` | Plus git branch, dirty marker, and exit code on failure |

## Dropped

| Thing | Why |
| --- | --- |
| `kube_aliases` (633 lines), `aws`, `azure`, `gcloud`, `cri` | Vendor-era tooling, unused |
| `nvcclient_aliases`, `quark_aliases`, `seclab_aliases` (~875 lines) | Job-specific, no longer relevant |
| `screen.conf.d/`, `screen_aliases` | Superseded by tmux |
| `kitty/`, `vscode/` | Terminal and editor are configured in their own apps now |
| nvim: mason, nvim-lspconfig, nvim-cmp, copilot, bufferline, toggleterm, whichkey, marks, conform, fugitive | The coding harnesses do this work now; these were most of the startup cost |
| `apikeys`, the key in `bash/bashrc` | See below |
| `TERM=screen-256color` forced in bashrc | Broke colours and keys over ssh; terminals set `TERM` correctly on their own |
| `tput cup 9999 0` at shell start | Scrolled the screen on every new shell |
| Hardcoded `/home/brendan` and `/Users/brendank` paths, NetApp GOPROXY, Rancher Desktop block | Not portable |
| nvim `BufEnter` auto-`lcd` | Silently changed the working directory, which fights telescope's project root and `:!` commands |
| Nested tmux via `$TMUX_PARENT` and config-file swapping | Replaced by `F12` off-mode — one server, no state to desync |

## Secrets

`dot-files/bash/bashrc` held a live `ANTHROPIC_API_KEY` inline. It was never
committed — verified with `git log -S` across all refs and by scanning every
blob in the object database — so it never reached the `origin` remote and did
not need rotating. `dev-config/apikeys` was never tracked either.

It was one `git add -A` away from being published, though, which is the reason
for the arrangement here rather than any actual leak:

- `~/.config/me/secrets.env`, mode 600, outside the checkout entirely
- `secrets.env.example` in the repo lists only the variable names
- `scripts/pre-commit` blocks key-shaped strings; enable it per repo with
  `git config core.hooksPath scripts`

## Cutover

The old symlinks in `$HOME` point into `~/dot-files`. `install.sh` replaces them
and moves anything real into `~/.me-backup/`. To go back:

```bash
rm ~/.bashrc ~/.tmux.conf ~/.config/nvim
ln -s ~/dot-files/bash/bashrc ~/.bashrc
ln -s ~/dot-files/tmux/tmux.conf ~/.tmux.conf
ln -s ~/dot-files/brendank-nvim ~/.config/nvim
```

## Adding something back

Find it in the old repo and move it into the right `rc.d` module:

```bash
git -C ~/dot-files grep -n 'the-alias'
```
