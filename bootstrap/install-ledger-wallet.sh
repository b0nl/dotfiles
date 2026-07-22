#!/usr/bin/env bash
set -euo pipefail

DOTFILES_GIT_DIR="$HOME/.dotfiles"
MACHINE="${DOTFILES_MACHINE:-}"

if [ -z "$MACHINE" ] && [ -d "$DOTFILES_GIT_DIR" ]; then
  MACHINE="$(
    /usr/bin/git \
      --git-dir="$DOTFILES_GIT_DIR" \
      --work-tree="$HOME" \
      config --local --get dotfiles.machine 2>/dev/null || true
  )"
fi

if [ "$MACHINE" != "personal" ]; then
  echo "==> Skipping Ledger Wallet: personal machines only"
  exit 0
fi

case "$(uname -m)" in
  x86_64|amd64)
    ;;
  *)
    echo "ERROR: Ledger Wallet's Linux AppImage requires x86_64/AMD64." >&2
    exit 1
    ;;
esac

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required to install Ledger USB rules." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

APP_DIR="$HOME/.local/opt/ledger-wallet"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

APPIMAGE="$APP_DIR/ledger-wallet.AppImage"
DOWNLOAD="$TMP_DIR/ledger-wallet.AppImage"
RULES_FILE="$TMP_DIR/20-ledger.rules"

DOWNLOAD_URL="https://download.live.ledger.com/latest/linux"

echo "==> Installing Ledger Wallet runtime support"

if command -v apt-get >/dev/null 2>&1; then
  FUSE_PACKAGE=""

  if apt-cache show libfuse2t64 >/dev/null 2>&1; then
    FUSE_PACKAGE="libfuse2t64"
  elif apt-cache show libfuse2 >/dev/null 2>&1; then
    FUSE_PACKAGE="libfuse2"
  fi

  if [ -n "$FUSE_PACKAGE" ] &&
    ! dpkg-query -W -f='${Status}' "$FUSE_PACKAGE" 2>/dev/null |
      grep -q 'install ok installed'; then
    sudo apt-get update
    sudo apt-get install -y "$FUSE_PACKAGE"
  fi
fi

echo "==> Installing Ledger USB rules"

cat > "$RULES_FILE" <<'RULES'
# Ledger HW.1 and Nano
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"

# Ledger devices using vendor ID 2c97
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
RULES

sudo install \
  -m 0644 \
  "$RULES_FILE" \
  /etc/udev/rules.d/20-ledger.rules

if command -v udevadm >/dev/null 2>&1; then
  sudo udevadm control --reload-rules
  sudo udevadm trigger
fi

echo "==> Downloading Ledger Wallet from Ledger"

curl \
  --fail \
  --location \
  --proto '=https' \
  --retry 3 \
  --show-error \
  --silent \
  "$DOWNLOAD_URL" \
  --output "$DOWNLOAD"

if [ ! -s "$DOWNLOAD" ]; then
  echo "ERROR: Ledger Wallet download is empty." >&2
  exit 1
fi

FILE_MAGIC="$(
  od -An -tx1 -N4 "$DOWNLOAD" |
    tr -d ' \n'
)"

if [ "$FILE_MAGIC" != "7f454c46" ]; then
  echo "ERROR: Downloaded file is not a valid Linux executable." >&2
  exit 1
fi

echo "==> Downloaded binary"
echo "    SHA-512: $(sha512sum "$DOWNLOAD" | awk '{print $1}')"

install -d "$APP_DIR" "$BIN_DIR" "$DESKTOP_DIR"
install -m 0755 "$DOWNLOAD" "$APPIMAGE"

cat > "$BIN_DIR/ledger-wallet" <<'WRAPPER'
#!/usr/bin/env bash
exec "$HOME/.local/opt/ledger-wallet/ledger-wallet.AppImage" "$@"
WRAPPER

chmod 0755 "$BIN_DIR/ledger-wallet"

cat > "$DESKTOP_DIR/ledger-wallet.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Ledger Wallet
Comment=Manage assets with a Ledger hardware wallet
Exec=$HOME/.local/bin/ledger-wallet
TryExec=$HOME/.local/bin/ledger-wallet
Icon=applications-finance
Terminal=false
Categories=Finance;Utility;
DESKTOP

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi

echo "==> Ledger Wallet installed"
echo "    Command: ledger-wallet"
echo "    AppImage: $APPIMAGE"
