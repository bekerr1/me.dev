# Upstream Kubernetes clients in the user's bin directory and a local Docker
# runtime managed by systemd on Linux or Docker Desktop on macOS.

# shellcheck disable=SC1091
. "$ME_ROOT/tools.env"

if [[ $ME_NO_NET == 1 ]]; then
  partial "not installing cloud tools (--no-net)"
  return 0
fi

case "$(os_name)" in
  linux) cloud_os=linux ;;
  macos) cloud_os=darwin ;;
  *) partial "cloud CLI downloads are unavailable on this OS"; return 0 ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  cloud_arch=amd64; docker_arch=x86_64 ;;
  aarch64|arm64) cloud_arch=arm64; docker_arch=aarch64 ;;
  *) partial "cloud CLI downloads are unavailable on this architecture"; return 0 ;;
esac

install_cloud_cli() {
  local name="$1" version="$2" repo="" url checksum_url
  local dest="$HOME/.local/bin/$name" installed=""
  own "$dest"

  case "$name" in
    helm) repo=helm/helm ;;
    kind) repo=kubernetes-sigs/kind ;;
  esac

  if [[ $version == latest ]]; then
    if [[ $ME_DRY_RUN == 1 ]]; then
      ok "dry run: would resolve and install the latest $name -> $(prettify "$dest")"
      return 0
    fi
    if [[ $name == kubectl ]]; then
      version=$(curl -fsSL https://dl.k8s.io/release/stable.txt) || version=""
    else
      version=$(curl -fsSL -o /dev/null -w '%{url_effective}' \
        "https://github.com/$repo/releases/latest") || version=""
      version="${version##*/}"
    fi
  fi

  if [[ ! ${version#v} =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.+-]+)?$ ]]; then
    warn "$name: expected a release version or latest"
    return 1
  fi
  version="v${version#v}"

  case "$name" in
    kubectl)
      url="https://dl.k8s.io/release/$version/bin/$cloud_os/$cloud_arch/kubectl"
      checksum_url="$url.sha256"
      ;;
    helm)
      url="https://get.helm.sh/helm-$version-$cloud_platform.tar.gz"
      checksum_url="$url.sha256sum"
      ;;
    kind)
      url="https://github.com/$repo/releases/download/$version/kind-$cloud_platform"
      checksum_url="$url.sha256sum"
      ;;
  esac

  if [[ -x $dest ]]; then
    case "$name" in
      kubectl) installed=$("$dest" version --client 2>/dev/null | awk '/^Client Version:/ {print $3}') ;;
      helm)    installed=$("$dest" version --template '{{.Version}}' 2>/dev/null) ;;
      kind)    installed=$("$dest" version -q 2>/dev/null) ;;
    esac
    if [[ ${installed#v} == "${version#v}" ]]; then
      skip "$name $version"
      return 0
    fi
  fi

  if [[ $ME_DRY_RUN == 1 ]]; then
    ok "dry run: would install $name $version -> $(prettify "$dest")"
    return 0
  fi

  if (
    mkdir -p "$(dirname "$dest")" &&
      tmp=$(mktemp -d "$(dirname "$dest")/.cloud-tools.XXXXXX") || exit 1
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$url" -o "$tmp/download" &&
      checksum=$(curl -fsSL "$checksum_url" | awk 'NR == 1 {print $1}') || exit 1
    actual=$(shasum -a 256 "$tmp/download") || exit 1
    [[ ${actual%% *} == "$checksum" ]] || exit 1

    if [[ $name == helm ]]; then
      tar xzf "$tmp/download" -C "$tmp" "$cloud_platform/helm" || exit 1
      install -m 0755 "$tmp/$cloud_platform/helm" "$tmp/$name" || exit 1
    else
      install -m 0755 "$tmp/download" "$tmp/$name" || exit 1
    fi

    if [[ -e $dest || -L $dest ]] &&
      ! grep -Fxq "$ME_GROUP"$'\t'"$dest" "$ME_MANIFEST" 2>/dev/null; then
      mkdir -p "$ME_BACKUP" &&
        cp -Pp "$dest" "$ME_BACKUP/$name.$(date +%Y%m%d-%H%M%S)" || exit 1
      printf '  backed up existing %s to %s\n' "$(prettify "$dest")" "$(prettify "$ME_BACKUP")"
    fi
    mv -f "$tmp/$name" "$dest"
  ); then
    ok "$name $version -> $(prettify "$dest")"
  else
    warn "$name: could not install a verified $version release"
    return 1
  fi
}

cloud_platform="$cloud_os-$cloud_arch"

cloud_failed=0
if [[ $cloud_os == linux ]]; then
  pkg_install iptables
  # shellcheck disable=SC1091
  . "$ME_ROOT/lib/docker.sh"
  install_docker_engine "$docker_arch" || { warn "Docker Engine setup did not complete"; cloud_failed=1; }
else
  pkg_install docker-desktop:/Applications/Docker.app/Contents/Resources/bin/docker
fi
install_cloud_cli kubectl "$KUBECTL_VERSION" || cloud_failed=1
install_cloud_cli helm "$HELM_VERSION" || cloud_failed=1
install_cloud_cli kind "$KIND_VERSION" || cloud_failed=1
return "$cloud_failed"
