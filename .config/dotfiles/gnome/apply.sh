#!/usr/bin/env bash
set -euo pipefail

GNOME_DIR="$HOME/.config/dotfiles/gnome"

if ! command -v dconf >/dev/null 2>&1; then
  echo "ERROR: dconf command not found"
  echo "Install it with: sudo apt install dconf-cli"
  exit 1
fi

load_dconf() {
  local path="$1"
  local input="$2"
  local label="$3"

  if [ ! -f "$input" ]; then
    echo "==> Skipping $label; file not found:"
    echo "    $input"
    return 0
  fi

  echo "==> Applying $label"
  echo "    $input -> $path"

  dconf load "$path" < "$input"
}

load_dconf \
  /org/gnome/terminal/legacy/profiles:/ \
  "$GNOME_DIR/configs/profiles.dconf" \
  "GNOME Terminal profiles"

load_dconf \
  /org/gnome/desktop/interface/ \
  "$GNOME_DIR/configs/desktop-interface.dconf" \
  "GNOME desktop interface settings"

load_dconf \
  /org/gnome/desktop/wm/keybindings/ \
  "$GNOME_DIR/configs/wm-keybindings.dconf" \
  "GNOME window manager keybindings"

load_dconf \
  /org/gnome/settings-daemon/plugins/media-keys/ \
  "$GNOME_DIR/configs/media-keys.dconf" \
  "GNOME media/custom keybindings"

echo
echo "==> GNOME settings applied"
echo "==> You may need to log out/in or restart GNOME apps to see every change."