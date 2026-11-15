#!/usr/bin/env bash
set -euo pipefail

EXTENSIONS_FILE="$HOME/.config/Code/User/extensions.txt"

echo "==> Installing VSCode extensions"

if ! command -v code >/dev/null 2>&1; then
  echo "==> Installing VSCode from Microsoft's official Debian package"

  case "$(dpkg --print-architecture)" in
    amd64) VSCODE_ARCH=x64 ;;
    arm64) VSCODE_ARCH=arm64 ;;
    armhf) VSCODE_ARCH=armhf ;;
    *) echo "ERROR: Unsupported VSCode architecture." >&2; exit 1 ;;
  esac

  VSCODE_TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$VSCODE_TMP_DIR"' EXIT

  curl --fail --location --silent --show-error \
    --proto '=https' --proto-redir '=https' --retry 3 \
    --connect-timeout 15 --max-time 300 \
    "https://update.code.visualstudio.com/latest/linux-deb-$VSCODE_ARCH/stable" \
    --output "$VSCODE_TMP_DIR/code.deb"

  if [ "$(dpkg-deb -f "$VSCODE_TMP_DIR/code.deb" Package)" != code ]; then
    echo "ERROR: Download is not the expected VSCode package." >&2
    exit 1
  fi

  # Allow apt's download user to read this public package.
  chmod 0755 "$VSCODE_TMP_DIR"
  chmod 0644 "$VSCODE_TMP_DIR/code.deb"

  printf '%s\n' 'code code/add-microsoft-repo boolean true' |
    sudo debconf-set-selections
  sudo apt-get install -y "$VSCODE_TMP_DIR/code.deb"
fi

if [ ! -f "$EXTENSIONS_FILE" ]; then
  echo "==> No VSCode extensions file found at:"
  echo "    $EXTENSIONS_FILE"
  echo "==> Skipping VSCode extension install."
  exit 0
fi

grep -vE '^\s*(#|$)' "$EXTENSIONS_FILE" | while read -r ext; do
  echo "==> Installing VSCode extension: $ext"
  code --install-extension "$ext"
done

echo "==> VSCode extension install complete"