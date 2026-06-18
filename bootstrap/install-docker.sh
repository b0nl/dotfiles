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

echo "==> Enabling Docker service"

sudo systemctl enable docker >/dev/null 2>&1 || true
sudo systemctl start docker >/dev/null 2>&1 || true

echo
echo "==> Docker installation complete"
echo "==> Docker version:"
docker --version || true

echo
echo "IMPORTANT:"
echo "You may need to log out and log back in before running docker without sudo."
echo "After re-login, test with:"
echo "  docker run hello-world"