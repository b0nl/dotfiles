#!/bin/bash

# ------------------------------------------------------------
# Dotfiles Git helper
# ------------------------------------------------------------

dotfiles() {
  /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

# ------------------------------------------------------------
# Dotfiles aliases
# ------------------------------------------------------------

alias dots='dotfiles status'
alias dotsb='dotfiles status -sb'
alias dotsd='dotfiles diff'
alias dotsdt='dotfiles difftool'
alias dotsn='dotfiles diff --name-only'
alias dotsstat='dotfiles diff --stat'
alias dotsa='dotfiles add'
alias dotsc='dotfiles commit'
alias dotsp='dotfiles push'
alias dotsl='dotfiles log --oneline --graph --decorate'
alias dotsu='dotfiles-audit'
alias dotsua='dotfiles-audit-all'

# ------------------------------------------------------------
# Dotfiles local Git configuration
# ------------------------------------------------------------

dotfiles-ensure-config() {
  dotfiles config --local status.showUntrackedFiles no
  dotfiles config --local core.hooksPath "$HOME/.config/dotfiles/git-hooks"

  if command -v code >/dev/null 2>&1; then
    dotfiles config --local diff.tool vscode
    dotfiles config --local difftool.vscode.cmd 'code --wait --diff "$LOCAL" "$REMOTE"'
    dotfiles config --local difftool.prompt false
  fi
}

# ------------------------------------------------------------
# Audit untracked candidates
# ------------------------------------------------------------

dotfiles-audit() {
  dotfiles status --short --untracked-files=all \
    | awk '/^\?\?/ {sub(/^\?\? /, ""); print}' \
    | grep -Ev '^(\.cache/|\.local/|\.mozilla/|\.thunderbird/|\.npm/|\.cargo/|\.rustup/|\.ssh/|\.aws/|\.gnupg/|\.pki/|\.docker/|\.dotnet/|\.android/|\.config/google-chrome/|\.config/chromium/|\.config/discord/|\.config/spotify/|Downloads/|Documents/|Pictures/|Videos/|Music/|dev/|mlpipeline/|dolt_repos/)' \
    | sort || true
}

dotfiles-audit-all() {
  dotfiles status --short --untracked-files=all
}

# ------------------------------------------------------------
# Interactive add helper
# ------------------------------------------------------------

dotfiles-pick() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is not installed"
    return 1
  fi

  dotfiles-audit | fzf -m | while read -r file; do
    [ -z "$file" ] && continue
    dotfiles add "$file"
    echo "Added: $file"
  done
}