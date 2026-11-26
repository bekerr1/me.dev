# System packages: the few things that have to come from the OS package manager.
#
# The package installer uses sudo on Linux only when a package is missing.
#
#   core     curl, git, tmux    every machine, --minimal included; the rest
#                               of the installer downloads with curl
#   dev      neovim, ripgrep,   the editor and what it leans on; skipped by
#            fzf, gcc (linux)   --minimal. gcc is the system C compiler and
#                               linker Rust links with (see rust.sh); C only.
#   desktop  ghostty            the default terminal; skipped by --minimal
#
# Entries are `package` or `package:command` when the two names differ.
#
# --no-net installs nothing and only reports what is missing.

ME_CORE_PKGS=(curl git tmux)
ME_DEV_PKGS=(neovim:nvim ripgrep:rg fzf)
# Checked by path: pixi's gcc is on PATH too, and does not count.
[[ $(os_name) == linux ]] && ME_DEV_PKGS+=(gcc:/usr/bin/cc)
ME_DESKTOP_PKGS=(ghostty)

pkg_install "${ME_CORE_PKGS[@]}"

section desktop
if [[ $ME_MINIMAL == 1 ]]; then
  partial "skipping dev tools and desktop apps (--minimal)"
  return 0 2>/dev/null || true
fi

pkg_install "${ME_DEV_PKGS[@]}" "${ME_DESKTOP_PKGS[@]}"

# Ghostty as the default terminal. Ubuntu 25.04+ (and other xdg-terminal-exec
# desktops) launch Ctrl+Alt+T and "open in terminal" through this list; the copy
# in ~/.config takes precedence over the system ones in /usr/share. macOS has no
# equivalent setting -- Ghostty just gets launched from the Dock.
if [[ $(os_name) == linux ]] && have ghostty; then
  generate "$HOME/.config/xdg-terminals.list" <<< com.mitchellh.ghostty.desktop
fi
