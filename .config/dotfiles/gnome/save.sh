#!/usr/bin/env bash
set -euo pipefail

GNOME_DIR="$HOME/.config/dotfiles/gnome"

if ! command -v dconf >/dev/null 2>&1; then
  echo "ERROR: dconf command not found"
  echo "Install it with: sudo apt install dconf-cli"
  exit 1
fi

dump_dconf() {
  local path="$1"
  local output="$2"
  local label="$3"

  mkdir -p "$(dirname "$output")"

  echo "==> Saving $label"
  echo "    $path -> $output"

  dconf dump "$path" > "$output"
}

dump_dconf \
  /org/gnome/terminal/legacy/profiles:/ \
  "$GNOME_DIR/configs/profiles.dconf" \
  "GNOME Terminal profiles"

dump_dconf \
  /org/gnome/desktop/interface/ \
  "$GNOME_DIR/configs/desktop-interface.dconf" \
  "GNOME desktop interface settings"

dump_dconf \
  /org/gnome/desktop/wm/keybindings/ \
  "$GNOME_DIR/configs/wm-keybindings.dconf" \
  "GNOME window manager keybindings"

dump_dconf \
  /org/gnome/settings-daemon/plugins/media-keys/ \
  "$GNOME_DIR/configs/media-keys.dconf" \
  "GNOME media/custom keybindings"

echo
echo "==> GNOME settings saved"