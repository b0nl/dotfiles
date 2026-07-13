#!/usr/bin/env bash
set -euo pipefail

PACKAGES_DIR="$HOME/.config/dotfiles/packages"

install_snap_packages() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "==> Snap package list not found: $file"
    return 0
  fi

  echo "==> Installing snap packages from $file"

  grep -vE '^\s*(#|$)' "$file" | while read -r line; do
    [ -z "$line" ] && continue

    local pkg
    pkg="$(echo "$line" | awk '{print $1}')"

    if snap list "$pkg" >/dev/null 2>&1; then
      echo "==> Snap already installed: $pkg"
      continue
    fi

    echo "==> Installing snap: $line"

    # Intentionally unquoted because lines may contain flags:
    # code --classic
    # shellcheck disable=SC2086
    sudo snap install $line
  done
}

if ! command -v snap >/dev/null 2>&1; then
  echo "ERROR: snap is not installed."
  echo "Install it first with: sudo apt install snapd"
  exit 1
fi

echo "==> Installing base snap packages"
install_snap_packages "$PACKAGES_DIR/snap-base.txt"

DOTFILES_MACHINE="${DOTFILES_MACHINE:-$(
  /usr/bin/git \
    --git-dir="$HOME/.dotfiles" \
    config --local --get dotfiles.machine 2>/dev/null || true
)}"

DOTFILES_MACHINE="${DOTFILES_MACHINE:-personal}"

case "$DOTFILES_MACHINE" in
  work)
    echo "==> Installing work snap packages"
    install_snap_packages "$PACKAGES_DIR/snap-work.txt"
    ;;
  personal)
    echo "==> Installing personal snap packages"
    install_snap_packages "$PACKAGES_DIR/snap-personal.txt"
    ;;
  *)
    echo "==> Unknown DOTFILES_MACHINE=$DOTFILES_MACHINE; skipping machine-specific snap packages"
    ;;
esac

echo "==> Snap installation complete"