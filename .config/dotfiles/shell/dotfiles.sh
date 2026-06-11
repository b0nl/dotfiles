# ~/.config/dotfiles/shell/dotfiles.sh

# ------------------------------------------------------------
# Dotfiles Git helper
# ------------------------------------------------------------

dotfiles() {
  /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"
}

# ------------------------------------------------------------
# Dotfiles aliases
# ------------------------------------------------------------

alias df='dotfiles status -sb'
alias dfs='dotfiles status'
alias dfd='dotfiles diff'
alias dfdt='dotfiles difftool'
alias dfn='dotfiles diff --name-only'
alias dfstat='dotfiles diff --stat'
alias dfa='dotfiles add'
alias dfc='dotfiles commit'
alias dfp='dotfiles push'
alias dfl='dotfiles log --oneline --graph --decorate'

# ------------------------------------------------------------
# Dotfiles local Git configuration
# ------------------------------------------------------------

dotfiles-ensure-config() {
  dotfiles config --local status.showUntrackedFiles no

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
    | grep '^??' \
    | sed 's/^?? //' \
    | grep -Ev '^(\.cache/|\.local/|\.mozilla/|\.thunderbird/|\.npm/|\.cargo/|\.rustup/|\.ssh/|\.aws/|\.gnupg/|\.pki/|\.docker/|\.dotnet/|\.android/|\.config/google-chrome/|\.config/chromium/|\.config/discord/|\.config/spotify/|Downloads/|Documents/|Pictures/|Videos/|Music/|dev/|mlpipeline/|dolt_repos/)' \
    | sort
}

dotfiles-audit-all() {
  dotfiles status --short --untracked-files=all
}

dotfiles-untracked() {
  /usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" status --short --untracked-files=all
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

# ------------------------------------------------------------
# Save helper
# ------------------------------------------------------------

dotfiles-save() {
  local msg="${1:-update dotfiles}"

  dotfiles status -sb
  dotfiles commit -m "$msg"
  dotfiles push
}