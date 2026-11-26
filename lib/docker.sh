# Install Docker's Linux bundle and keep its containerd and runc on the daemon's PATH.
install_docker_engine() (
  local version="${DOCKER_VERSION#v}" arch="$1"
  local unit=me-docker.service unit_path=/etc/systemd/system/me-docker.service
  local client=/usr/local/bin/docker base index file tmp dest
  local sudo=()
  [[ $EUID -eq 0 ]] || sudo=(sudo)

  if [[ $version != latest && ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    warn "Docker: expected a release version or latest"
    return 1
  fi
  if [[ $ME_DRY_RUN == 1 ]]; then
    info "dry run: would install Docker $version and bundled containerd, then enable $unit"
    return 0
  fi
  if [[ $EUID -ne 0 ]] && ! have sudo; then
    warn "Docker: sudo is required to install the system service"
    return 1
  fi
  if [[ ! -d /run/systemd/system ]]; then
    warn "Docker: the managed Linux service requires systemd"
    return 1
  fi
  if ! systemctl show --property=Version --value >/dev/null; then
    warn "Docker: could not connect to systemd"
    return 1
  fi
  if systemctl is-active --quiet docker.service docker.socket ||
    systemctl is-enabled --quiet docker.service docker.socket; then
    warn "Docker: disable the existing docker.service and docker.socket before switching to $unit"
    return 1
  fi
  if [[ -e $client || -L $client ]]; then
    case "$(readlink "$client")" in
      /opt/me/docker/*/docker) ;;
      *) warn "Docker: $client already exists outside this installer"; return 1 ;;
    esac
  fi

  base="https://download.docker.com/linux/static/stable/$arch"
  if [[ $version == latest ]]; then
    index=$(curl -fsSL "$base/") || return 1
    version=$(sed -nE 's/.*href="docker-([0-9]+\.[0-9]+\.[0-9]+)\.tgz".*/\1/p' <<< "$index" | sort -V | tail -n 1)
    [[ -n $version ]] || { warn "Docker: no stable release found for $arch"; return 1; }
  fi

  tmp=$(mktemp -d) || return 1
  trap 'rm -rf "$tmp"' EXIT
  file="docker-$version.tgz"
  dest="/opt/me/docker/$version"

  if [[ ! -x $dest/docker || ! -x $dest/dockerd ]]; then
    if [[ -z ${index:-} ]]; then
      index=$(curl -fsSL "$base/") || return 1
    fi
    if [[ $index != *"href=\"$file\""* && $version == *-* ]]; then
      base="https://download.docker.com/linux/static/test/$arch"
      index=$(curl -fsSL "$base/") || return 1
    fi
    if [[ $index != *"href=\"$file\""* ]]; then
      warn "Docker: upstream does not list $file for $arch"
      return 1
    fi
    curl -fsSL "$base/$file" -o "$tmp/$file" || return 1
    if [[ $index == *"href=\"$file.sha256\""* ]]; then
      local checksum actual
      checksum=$(curl -fsSL "$base/$file.sha256" | awk 'NR == 1 {print $1}') || return 1
      actual=$(sha256sum "$tmp/$file") || return 1
      [[ ${actual%% *} == "$checksum" ]] || { warn "Docker: checksum failed for $file"; return 1; }
    else
      warn "Docker: upstream publishes no checksum for $file"
    fi
    tar xzf "$tmp/$file" -C "$tmp" || return 1
    local binary
    for binary in docker dockerd containerd runc; do
      # Older bundles prefix the runtime binaries with docker-.
      [[ -x $tmp/docker/$binary || -x $tmp/docker/docker-$binary ]] ||
        { warn "Docker: $file is missing $binary"; return 1; }
    done
    local staging
    "${sudo[@]}" install -d -m 0755 "$(dirname "$dest")" || return 1
    staging=$("${sudo[@]}" mktemp -d "$dest.XXXXXX") || return 1
    if ! { "${sudo[@]}" chmod 0755 "$staging" &&
      "${sudo[@]}" install -m 0755 "$tmp/docker/"* "$staging/" &&
      "${sudo[@]}" mv -T "$staging" "$dest"; }; then
      "${sudo[@]}" rm -rf "$staging"
      return 1
    fi
  fi

  sed "s|@DOCKER_BIN@|$dest|g" "$ME_ROOT/lib/me-docker.service" > "$tmp/$unit" || return 1
  if ! getent group docker >/dev/null; then
    "${sudo[@]}" groupadd --system docker || return 1
  fi
  if ! cmp -s "$tmp/$unit" "$unit_path"; then
    if [[ -e $unit_path ]]; then
      cp "$unit_path" "$tmp/previous.service" || return 1
    fi
    "${sudo[@]}" install -m 0644 "$tmp/$unit" "$unit_path" || return 1
    if ! { "${sudo[@]}" systemctl daemon-reload &&
      "${sudo[@]}" systemctl enable "$unit" &&
      "${sudo[@]}" systemctl restart "$unit"; }; then
      if [[ -e $tmp/previous.service ]]; then
        "${sudo[@]}" install -m 0644 "$tmp/previous.service" "$unit_path" &&
          "${sudo[@]}" systemctl daemon-reload &&
          "${sudo[@]}" systemctl restart "$unit" || warn "Docker: could not restore the previous service"
      else
        "${sudo[@]}" systemctl disable --now "$unit" &&
          "${sudo[@]}" rm -f "$unit_path" &&
          "${sudo[@]}" systemctl daemon-reload || warn "Docker: could not clean up the failed service"
      fi
      return 1
    fi
    printf '  Docker %s enabled as %s\n' "$version" "$unit"
  elif ! systemctl is-active --quiet "$unit" || ! systemctl is-enabled --quiet "$unit"; then
    "${sudo[@]}" systemctl enable --now "$unit" || return 1
  fi

  if [[ $(readlink "$client") != "$dest/docker" ]]; then
    "${sudo[@]}" ln -sfn "$dest/docker" "$client" || return 1
  fi
)
