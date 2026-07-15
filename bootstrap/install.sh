#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_GIT_DIR="$HOME/.dotfiles"

"$SCRIPT_DIR/install-dotfiles.sh"

DOTFILES_MACHINE="${DOTFILES_MACHINE:-$(
  /usr/bin/git \
    --git-dir="$DOTFILES_GIT_DIR" \
    config --local --get dotfiles.machine 2>/dev/null || true
)}"

if [ -z "$DOTFILES_MACHINE" ]; then
  if [ ! -t 0 ]; then
    echo "ERROR: Cannot prompt for machine type in a non-interactive shell."
    echo "Run with DOTFILES_MACHINE=work or DOTFILES_MACHINE=personal."
    exit 1
  fi

  while true; do
    read -r -p "Is this a work laptop? [y/N] " answer

    case "$answer" in
      [Yy]|[Yy][Ee][Ss])
        DOTFILES_MACHINE="work"
        break
        ;;
      ""|[Nn]|[Nn][Oo])
        DOTFILES_MACHINE="personal"
        break
        ;;
      *)
        echo "Please answer yes or no."
        ;;
    esac
  done
fi

case "$DOTFILES_MACHINE" in
  work|personal)
    ;;
  *)
    echo "ERROR: Unknown machine type: $DOTFILES_MACHINE"
    exit 1
    ;;
esac

/usr/bin/git \
  --git-dir="$DOTFILES_GIT_DIR" \
  config --local dotfiles.machine "$DOTFILES_MACHINE"

export DOTFILES_MACHINE

echo "==> Machine type: $DOTFILES_MACHINE"

"$SCRIPT_DIR/install-apt.sh"
"$SCRIPT_DIR/install-snap.sh"
"$SCRIPT_DIR/install-uv.sh"
"$SCRIPT_DIR/install-docker.sh"
"$SCRIPT_DIR/install-zotero.sh"
"$SCRIPT_DIR/install-nzbridge.sh"
"$SCRIPT_DIR/install-vscode.sh"
"$SCRIPT_DIR/install-gnome.sh"

echo "==> Full install complete"