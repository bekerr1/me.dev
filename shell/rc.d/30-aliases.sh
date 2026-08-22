# Core aliases. Deliberately small -- this replaces ~1900 lines of vendor-era
# aliases. Add back only what you actually reach for and find missing.

alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias vim='nvim'
alias v='nvim'

# Reload / edit this config.
alias brc='. ~/.bashrc'
alias vbrc='nvim ~/.config/me/root/shell/rc.d'

# Clipboard: same two commands on both platforms.
if [ "$(uname -s)" = Linux ]; then
  if command -v wl-copy >/dev/null 2>&1; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
  elif command -v xclip >/dev/null 2>&1; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  fi
fi

alias uuidgen='uuidgen | tr "[:upper:]" "[:lower:]"'

mkcd() { mkdir -p "$1" && cd "$1"; }

+x() { chmod +x "$@"; }

# untils 5 'curl -sf localhost:8080/health' -- poll until a command succeeds.
untils() {
  local delay=$1; shift
  until eval "$*"; do
    printf 'waiting %ss for: %s\n' "$delay" "$*"
    sleep "$delay"
  done
}

# Pretty-print a CSV as an aligned table.
csv() { sed -E 's/,,/, ,/g' "$1" | column -t -s ','; }
