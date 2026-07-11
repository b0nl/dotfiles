#!/usr/bin/env bash
set -euo pipefail

REPO_URL="git@github.com:b0nl/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup"
DOTFILES_PACKAGES_DIR="$HOME/.config/dotfiles/packages"

echo "==> Installing dotfiles"

# ------------------------------------------------------------
# Check git
# ------------------------------------------------------------

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is not installed."
  echo "Install git first, e.g.: sudo apt install git"
  exit 1
fi

# ------------------------------------------------------------
# Clone bare repo if needed
# ------------------------------------------------------------

if [ ! -d "$DOTFILES_DIR" ]; then
  echo "==> Cloning dotfiles repo"
  git clone --bare "$REPO_URL" "$DOTFILES_DIR"
else
  echo "==> Dotfiles repo already exists at $DOTFILES_DIR"
fi

# ------------------------------------------------------------
# Define dotfiles command locally for this script
# ------------------------------------------------------------

dotfiles() {
  /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

# ------------------------------------------------------------
# Checkout files, backing up conflicts
# ------------------------------------------------------------

mkdir -p "$BACKUP_DIR"

echo "==> Checking out dotfiles"

set +e
checkout_output="$(dotfiles checkout 2>&1)"
checkout_status=$?
set -e

if [ "$checkout_status" -ne 0 ]; then
  echo "==> Checkout conflicts detected"
  echo "==> Backing up conflicting files to $BACKUP_DIR"

  echo "$checkout_output" \
    | sed -n '/The following untracked working tree files would be overwritten by checkout:/,/Please move or remove them before you switch branches./p' \
    | sed '1d;$d' \
    | sed 's/^[[:space:]]*//' \
    | while read -r file; do
      [ -z "$file" ] && continue

      src="$HOME/$file"
      dst="$BACKUP_DIR/$file"

      if [ -e "$src" ]; then
        echo "Backing up: $file"
        mkdir -p "$(dirname "$dst")"
        mv "$src" "$dst"
      fi
    done

  echo "==> Retrying checkout"
  dotfiles checkout
fi

# ------------------------------------------------------------
# Configure local dotfiles Git behavior
# ------------------------------------------------------------

echo "==> Configuring dotfiles Git settings"

dotfiles config --local status.showUntrackedFiles no
dotfiles config --local core.hooksPath "$HOME/.config/dotfiles/git-hooks"

# VSCode difftool support
if command -v code >/dev/null 2>&1; then
  dotfiles config --local diff.tool vscode
  dotfiles config --local difftool.vscode.cmd 'code --wait --diff "$LOCAL" "$REMOTE"'
  dotfiles config --local difftool.prompt false
else
  echo "==> VSCode CLI 'code' not found; skipping VSCode difftool config"
fi

# ------------------------------------------------------------
# Set default profile if missing
# ------------------------------------------------------------

if [ ! -f "$HOME/.dotfiles-profile" ]; then
  echo "==> Creating default dotfiles profile: personal"
  echo "personal" > "$HOME/.dotfiles-profile"
fi

echo
echo "==> Dotfiles installation complete"
echo "==> Reload your shell with:"
echo "    source ~/.bashrc"
echo
echo "==> Current status:"
dotfiles status -sb

# ------------------------------------------------------------
# Package manifest helpers
# ------------------------------------------------------------

packages-edit() {
  mkdir -p "$DOTFILES_PACKAGES_DIR"

  if command -v code >/dev/null 2>&1; then
    code \
      "$DOTFILES_PACKAGES_DIR/apt-base.txt" \
      "$DOTFILES_PACKAGES_DIR/apt-work.txt" \
      "$DOTFILES_PACKAGES_DIR/apt-personal.txt" \
      "$DOTFILES_PACKAGES_DIR/snap-base.txt" \
      "$DOTFILES_PACKAGES_DIR/snap-work.txt" \
      "$DOTFILES_PACKAGES_DIR/snap-personal.txt"
  else
    ${EDITOR:-nano} "$DOTFILES_PACKAGES_DIR/apt-base.txt"
  fi
}
