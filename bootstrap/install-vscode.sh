#!/usr/bin/env bash
set -euo pipefail

EXTENSIONS_FILE="$HOME/.config/Code/User/extensions.txt"

echo "==> Installing VSCode extensions"

if ! command -v code >/dev/null 2>&1; then
  echo "ERROR: VSCode CLI 'code' not found."
  echo "Install VSCode first, then rerun this script."
  exit 1
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