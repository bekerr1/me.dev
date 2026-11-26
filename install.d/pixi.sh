# pixi: conda-forge package manager. The binary goes in ~/.pixi/bin, where
# `pixi self-update` and `pixi global` expect it; the global tool manifest is
# linked from pixi/pixi-global.toml and synced.
#
# Projects with native dependencies carry their own pixi.toml; this module only
# provides the binary and the user-wide tools.

# shellcheck disable=SC1091
. "$ME_ROOT/tools.env"

pixi_bin="$HOME/.pixi/bin/pixi"
own "$pixi_bin"

link "$ME_ROOT/pixi/pixi-global.toml" "$HOME/.pixi/manifests/pixi-global.toml"

section tools
if [[ $ME_NO_NET == 1 ]]; then
  partial "not installing pixi or its tools (--no-net)"
  return 0 2>/dev/null || true
fi

if [[ -x $pixi_bin ]] && [[ "$("$pixi_bin" --version 2>/dev/null)" == "pixi ${PIXI_VERSION#v}" ]]; then
  skip "pixi $PIXI_VERSION"
elif [[ $ME_DRY_RUN == 1 ]]; then
  ok "dry run: would install pixi $PIXI_VERSION"
else
  case "$(os_name)-$(uname -m)" in
    linux-x86_64)               target=x86_64-unknown-linux-musl ;;
    linux-aarch64|linux-arm64)  target=aarch64-unknown-linux-musl ;;
    macos-x86_64)               target=x86_64-apple-darwin ;;
    macos-arm64)                target=aarch64-apple-darwin ;;
    *) warn "pixi: unsupported platform $(os_name)-$(uname -m)"; return 0 ;;
  esac
  url="https://github.com/prefix-dev/pixi/releases/download/$PIXI_VERSION/pixi-$target.tar.gz"
  tmp=$(mktemp -d)
  if curl -fsSL "$url" | tar xz -C "$tmp" && [[ -x $tmp/pixi ]]; then
    mkdir -p "$(dirname "$pixi_bin")"
    install -m 0755 "$tmp/pixi" "$pixi_bin"
    ok "pixi $PIXI_VERSION -> $(prettify "$pixi_bin")"
  else
    warn "pixi: could not fetch $url"
  fi
  rm -rf "$tmp"
fi

# Converge the global tools on the manifest: installs what is listed, removes
# what is not. The environments live under ~/.pixi/envs, owned by pixi.
if [[ $ME_DRY_RUN == 1 ]]; then
  skip "dry run: not running pixi global sync"
elif [[ -x $pixi_bin ]]; then
  if "$pixi_bin" global sync >/dev/null 2>&1; then
    info "pixi global tools match pixi/pixi-global.toml"
  else
    warn "pixi global sync failed; run it by hand to see why"
  fi
fi
