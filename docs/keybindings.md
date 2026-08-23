# Keybindings

## tmux — prefix `C-e`

`C-e` then the key, unless marked otherwise. `-r` keys repeat without
re-pressing the prefix.

### Windows

| Key | Action |
| --- | --- |
| `t` | New window, prompts for a name, appended at the end |
| `T` | New window at the index you type. If that index is taken, the rest shift right; if it's past the end, the window is created there and the gap is kept |
| `A` | Rename the current window (pre-filled) |
| `C-e` | Last window — the flip between the two you are actually using |
| `h` / `l` | Previous / next window |
| `H` / `L` | Move the current window left / right (`-r`) |
| `w` | Visual window and session picker |
| `X` | Kill the window, with confirmation |
| `1`–`9` | Jump to window by index |

### Panes

| Key | Action |
| --- | --- |
| `\|` or `%` | Split left/right, same directory |
| `-` or `"` | Split top/bottom, same directory |
| `j` `k` `n` `o` | Focus down / up / left / right (`-r`) |
| `←` `↓` `↑` `→` | Resize (`-r`) |
| `z` | Zoom the pane |
| `Space` | Cycle layout |
| `x` | Kill the pane |

### Sessions

| Key | Action |
| --- | --- |
| `S` | New session, prompts for a name |
| `(` / `)` | Previous / next session |
| `d` | Detach |

From the shell: `tms [name]` attach-or-create (defaults to the directory name),
`tmls` list, `tmks <name>` kill, `tmw <name> [index]` new window, `tmp` fuzzy
session picker.

### Copy mode

| Key | Action |
| --- | --- |
| `Enter` | Enter copy mode |
| `v` | Begin selection |
| `C-v` | Rectangle toggle |
| `y` | Copy and exit |
| `/` | Incremental search **up** through scrollback |
| `?` | Incremental search down |

### Persistence

| Key | Action |
| --- | --- |
| `C-s` | Save the whole session tree now |
| `C-r` | Restore it |

tmux-continuum also saves every 15 minutes and restores automatically when the
tmux server starts, so a reboot does not cost you your sessions. Window indices
and names survive exactly, including deliberate gaps; pane contents come back
too, so a restored window looks like the one you left.

Coding agents are deliberately **not** restarted on restore — only the shell,
its working directory, and editors/pagers. Restoring the cwd is the useful part;
relaunching claude/codex/pi across every agent window on every boot is not.

Snapshots live in `~/.local/share/tmux/resurrect`.

### Nested tmux — `F12`, no prefix

`F12` makes the **outer** tmux ignore every key, so all input reaches whatever
tmux is inside — a nested local server, or one at the far end of an ssh session.
The status bar collapses to a dim `OFF` marker so there is never any doubt about
which server is listening. `F12` again takes control back.

`C-e N` opens a genuinely nested tmux server on its own socket, for trying a
config change without disturbing the session you are working in.

## neovim — leader is `Space`

### Movement

| Key | Action |
| --- | --- |
| `J` / `K` | 15 lines down / up, recentred |
| `n` / `N` | Next / previous match, recentred |
| `C-d` / `C-u` | Half page, recentred |
| `<leader>j` | Join lines (what `J` normally does) |

### Files and windows

| Key | Action |
| --- | --- |
| `C-n` | Toggle the file tree, revealing the current file |
| `ss` | Save |
| `QQ` | Quit |
| `Esc` | Clear search highlight |
| `C-h/j/k/l` | Move between splits |

### Find — `<leader>f`

| Key | Action |
| --- | --- |
| `ff` | Find files |
| `fg` | Live grep (ripgrep) |
| `fw` | Grep the word under the cursor |
| `fb` | Buffers |
| `fr` | Recent files |
| `fc` | Fuzzy find in this buffer |
| `fd` | Diagnostics |
| `fh` | Help tags |

Inside a picker: `C-j`/`C-k` move, `Esc` closes.

### Git — `<leader>g`

| Key | Action |
| --- | --- |
| `]c` / `[c` | Next / previous hunk |
| `gp` | Preview hunk |
| `gs` | Stage hunk (works on a visual selection too) |
| `gr` | Reset hunk |
| `gb` | Toggle line blame |
| `gd` | Diff this file |

### Registers

Deletes go to the black hole register, so a yank survives an intervening
delete. `<leader>d` deletes normally when you want the text back, and `p` in
visual mode pastes the last *yank* rather than the last delete.

### Selection

`Enter` grows the selection by syntax node (expression → statement → block),
`Backspace` shrinks it.

## Cursor / VS Code

The same motions apply through the vscode-neovim extension: `J`/`K` travel,
`ss` saves, `d` does not clobber the yank register. Plus `C-n` explorer,
`H`/`L` previous/next editor, `C-f` last editor, `C-t` terminal.

## git

`git commit` opens a plugin-free nvim with a 72-column ruler and spell check.
`J`/`K` and `ss`/`QQ` work; nothing else is loaded.

| Alias | Command |
| --- | --- |
| `gs` | `git status -sb` |
| `gd` / `gds` | diff / staged diff |
| `ga` / `gap` | add / add -p |
| `gc <msg>` | commit -m |
| `gch` | checkout |
| `gb` | branch |
| `glo` | oneline graph, last 20 |
| `gp` / `gpl` | push / pull |
| `grc` / `gpc` | rebase / cherry-pick --continue |
| `gmreb` | interactive rebase onto the default branch |
| `pullmain` | update the default branch without leaving yours |
