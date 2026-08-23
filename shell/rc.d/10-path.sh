# PATH construction. Idempotent: re-sourcing .bashrc will not duplicate entries.

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) [ -d "$1" ] && PATH="$1:$PATH" ;;
  esac
}

path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) [ -d "$1" ] && PATH="$PATH:$1" ;;
  esac
}

# Lowest priority first; each prepend pushes the entry above the previous ones.
path_prepend /usr/local/bin
path_prepend /opt/homebrew/bin            # macOS arm64
path_prepend /opt/homebrew/sbin
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/go/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.config/me/root/bin"  # this repo's bin/
export PATH

# Go: only export if a toolchain is actually present.
if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$HOME/go}"
  export GOBIN="$GOPATH/bin"
  path_prepend "$GOBIN"
  export PATH
fi

# nvm is slow to source (~200ms). Load it lazily: the first call to node/npm/npx
# swaps in the real nvm, then re-runs the command.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  nvm_load() {
    unset -f nvm node npm npx nvm_load
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
    nvm use default >/dev/null 2>&1
  }
  nvm()  { nvm_load; nvm "$@"; }
  node() { nvm_load; node "$@"; }
  npm()  { nvm_load; npm "$@"; }
  npx()  { nvm_load; npx "$@"; }
fi
