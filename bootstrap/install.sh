#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/install-dotfiles.sh"
"$SCRIPT_DIR/install-apt.sh"
"$SCRIPT_DIR/install-snap.sh"
"$SCRIPT_DIR/install-uv.sh"
"$SCRIPT_DIR/install-docker.sh"
"$SCRIPT_DIR/install-zotero.sh"
"$SCRIPT_DIR/install-vscode.sh"
"$SCRIPT_DIR/install-gnome.sh"

echo "==> Full install complete"