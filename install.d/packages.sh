# System packages: the few things that have to come from the OS package manager.
#
# This is the one module that may use sudo, and only when something is actually
# missing -- a re-run on a machine that already has everything never prompts.
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

# pkg_install <pkg[:cmd]>...  -- install whichever of these are missing.
pkg_install() {
  local missing=() spec p
  for spec in "$@"; do
    p="${spec%%:*}"
    if have "${spec##*:}"; then skip "$p"; else missing+=("$p"); fi
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  if [[ $ME_NO_NET == 1 ]]; then
    partial
    warn "missing: ${missing[*]} (not installing with --no-net)"
    return 0
  fi

  case "$(os_name)" in
    macos)
      if ! have brew; then
        warn "missing: ${missing[*]} -- install Homebrew first: https://brew.sh"
        return 0
      fi
      for p in "${missing[@]}"; do
        case "$p" in
          ghostty) run brew install --cask ghostty ;;
          *)       run brew install "$p" ;;
        esac && ok "$p"
      done
      ;;
    linux)
      if ! have apt-get; then
        warn "missing: ${missing[*]} -- no apt-get here, install them with your package manager"
        return 0
      fi
      local sudo=()
      [[ $EUID -ne 0 ]] && sudo=(sudo)
      if [[ ${#sudo[@]} -gt 0 ]] && ! have sudo; then
        warn "missing: ${missing[*]} -- no sudo, ask an admin to install them"
        return 0
      fi
      log "  apt-get install ${missing[*]} (may ask for your password)"
      run "${sudo[@]}" apt-get update -qq \
        && run "${sudo[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" \
        && ok "installed ${missing[*]}" \
        || warn "apt-get install failed: ${missing[*]}"
      ;;
    *)
      warn "missing: ${missing[*]} -- unknown OS, install them by hand"
      ;;
  esac
}

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
