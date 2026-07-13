#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Docker Engine"

if command -v docker >/dev/null 2>&1; then
  echo "==> Docker already installed: $(docker --version)"
else
  echo "==> Removing conflicting Docker packages if present"

  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt remove -y "$pkg" >/dev/null 2>&1 || true
  done

  echo "==> Installing Docker apt prerequisites"

  sudo apt update
  sudo apt install -y ca-certificates curl

  echo "==> Adding Docker official GPG key"

  sudo install -m 0755 -d /etc/apt/keyrings

  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo "==> Adding Docker apt repository"

  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  echo "==> Installing Docker packages"

  sudo apt update
  sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

echo "==> Ensuring docker group exists"

sudo groupadd docker >/dev/null 2>&1 || true

echo "==> Adding current user to docker group"

sudo usermod -aG docker "$USER"

echo "==> Starting/enabling Docker service if systemd is available"

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
  sudo systemctl enable docker
  sudo systemctl start docker
else
  echo "==> systemd is not available or not running; skipping Docker service enable/start"
  echo "==> You may need to start Docker manually, or use Docker Desktop if this is WSL"
fi

DOTFILES_MACHINE="${DOTFILES_MACHINE:-$(
  /usr/bin/git \
    --git-dir="$HOME/.dotfiles" \
    config --local --get dotfiles.machine 2>/dev/null || true
)}"

if [ "$DOTFILES_MACHINE" = "work" ]; then
  DOCKER_CONFIG_FILE="$HOME/.docker/config.json"
  WORK_REGISTRY="hub.braincreators.com"

  if [ -f "$DOCKER_CONFIG_FILE" ] &&
     grep -Fq "\"$WORK_REGISTRY\"" "$DOCKER_CONFIG_FILE"; then
    echo "==> Docker credentials already configured for $WORK_REGISTRY"
  else
    echo "==> Logging in to work Docker registry"
    docker login "$WORK_REGISTRY"
  fi
fi

echo
echo "==> Docker installation complete"
echo "==> Docker version:"
docker --version || true

echo
echo "IMPORTANT:"
echo "You may need to log out and log back in before running docker without sudo."
echo "After re-login, test with:"
echo "  docker run hello-world"