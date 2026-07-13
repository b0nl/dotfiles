#!/usr/bin/env bash
set -euo pipefail

PACKAGES_DIR="$HOME/.config/dotfiles/packages"

install_apt_packages() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "==> Apt package list not found: $file"
    return 0
  fi

  echo "==> Installing apt packages from $file"

  local packages
  packages="$(grep -vE '^\s*(#|$)' "$file" || true)"

  if [ -z "$packages" ]; then
    echo "==> No apt packages listed in $file"
    return 0
  fi

  # shellcheck disable=SC2086
  sudo apt install -y $packages
}

echo "==> Updating apt"
sudo apt update

echo "==> Installing base apt packages"
install_apt_packages "$PACKAGES_DIR/apt-base.txt"

DOTFILES_MACHINE="${DOTFILES_MACHINE:-$(
  /usr/bin/git \
    --git-dir="$HOME/.dotfiles" \
    config --local --get dotfiles.machine 2>/dev/null || true
)}"

DOTFILES_MACHINE="${DOTFILES_MACHINE:-personal}"

case "$DOTFILES_MACHINE" in
  work)
    echo "==> Installing work apt packages"
    install_apt_packages "$PACKAGES_DIR/apt-work.txt"
    ;;
  personal)
    echo "==> Installing personal apt packages"
    install_apt_packages "$PACKAGES_DIR/apt-personal.txt"
    ;;
  *)
    echo "==> Unknown DOTFILES_MACHINE=$DOTFILES_MACHINE; skipping machine-specific apt packages"
    ;;
esac

echo "==> Apt installation complete"