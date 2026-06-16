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

DOTFILES_PROFILE="${DOTFILES_PROFILE:-personal}"

if [ -f "$HOME/.dotfiles-profile" ]; then
  read -r DOTFILES_PROFILE < "$HOME/.dotfiles-profile"
fi

case "$DOTFILES_PROFILE" in
  work)
    echo "==> Installing work apt packages"
    install_apt_packages "$PACKAGES_DIR/apt-work.txt"
    ;;
  personal)
    echo "==> Installing personal apt packages"
    install_apt_packages "$PACKAGES_DIR/apt-personal.txt"
    ;;
  *)
    echo "==> Unknown DOTFILES_PROFILE=$DOTFILES_PROFILE; skipping profile apt packages"
    ;;
esac

echo "==> Apt installation complete"