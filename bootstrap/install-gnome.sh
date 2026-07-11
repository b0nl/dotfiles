#!/usr/bin/env bash
set -euo pipefail

APPLY_SCRIPT="$HOME/.config/dotfiles/gnome/apply.sh"

echo "==> Applying GNOME settings"

if ! command -v dconf >/dev/null 2>&1; then
  echo "==> dconf command not found; skipping GNOME settings"
  echo "==> Install with: sudo apt install dconf-cli"
  exit 0
fi

if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  echo "==> No graphical session detected; skipping GNOME settings"
  exit 0
fi

if [ ! -f "$APPLY_SCRIPT" ]; then
  echo "==> GNOME apply script not found; skipping:"
  echo "    $APPLY_SCRIPT"
  exit 0
fi

if [ ! -x "$APPLY_SCRIPT" ]; then
  echo "==> GNOME apply script is not executable; making it executable"
  chmod +x "$APPLY_SCRIPT"
fi

"$APPLY_SCRIPT"