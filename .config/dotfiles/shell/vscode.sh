#!/bin/bash

# ------------------------------------------------------------
# VSCode helpers
# ------------------------------------------------------------

vscode-save-extensions() {
  if ! command -v code >/dev/null 2>&1; then
    echo "ERROR: VSCode CLI 'code' not found"
    return 1
  fi

  mkdir -p "$HOME/.config/Code/User"
  code --list-extensions | sort > "$HOME/.config/Code/User/extensions.txt"

  echo "==> Saved VSCode extensions to:"
  echo "    $HOME/.config/Code/User/extensions.txt"
}

vscode-install-extensions() {
  local file="$HOME/.config/Code/User/extensions.txt"

  if ! command -v code >/dev/null 2>&1; then
    echo "ERROR: VSCode CLI 'code' not found"
    return 1
  fi

  if [ ! -f "$file" ]; then
    echo "ERROR: VSCode extensions file not found: $file"
    return 1
  fi

  grep -vE '^\s*(#|$)' "$file" | while read -r ext; do
    [ -z "$ext" ] && continue
    echo "==> Installing VSCode extension: $ext"
    code --install-extension "$ext"
  done
}

vscode-edit-settings() {
  code \
    "$HOME/.config/Code/User/settings.json" \
    "$HOME/.config/Code/User/keybindings.json" \
    "$HOME/.config/Code/User/extensions.txt"
}

vscode-save-config() {
  vscode-save-extensions

  dotfiles add \
    .config/Code/User/settings.json \
    .config/Code/User/keybindings.json \
    .config/Code/User/snippets \
    .config/Code/User/extensions.txt

  dotfiles status -sb
}