#!/bin/bash

# ------------------------------------------------------------
# Dotfiles health check
# ------------------------------------------------------------

_dotfiles_health_green="\033[0;32m"
_dotfiles_health_red="\033[0;31m"
_dotfiles_health_yellow="\033[0;33m"
_dotfiles_health_blue="\033[0;34m"
_dotfiles_health_reset="\033[0m"

health_ok() {
  printf "${_dotfiles_health_green}OK${_dotfiles_health_reset}: %s\n" "$*"
}

health_missing() {
  printf "${_dotfiles_health_red}MISSING${_dotfiles_health_reset}: %s\n" "$*"
}

health_warn() {
  printf "${_dotfiles_health_yellow}WARN${_dotfiles_health_reset}: %s\n" "$*"
}

health_section() {
  printf "\n${_dotfiles_health_blue}==> %s${_dotfiles_health_reset}\n" "$*"
}

dotfiles-health() {
  health_section "Dotfiles"

  if type dotfiles >/dev/null 2>&1; then
    dotfiles status -sb
  else
    health_missing "dotfiles function not available"
  fi

  health_section "Profile"

  if [ -f "$HOME/.dotfiles-profile" ]; then
    local profile
    profile="$(cat "$HOME/.dotfiles-profile")"
    health_ok "~/.dotfiles-profile = $profile"
  else
    health_warn "No ~/.dotfiles-profile found"
  fi

  health_section "Core commands"

  for cmd in git curl uv docker code zotero; do
    if command -v "$cmd" >/dev/null 2>&1; then
      health_ok "$cmd -> $(command -v "$cmd")"
    else
      health_missing "$cmd"
    fi
  done

  health_section "VSCode config"

  for file in \
    "$HOME/.config/Code/User/settings.json" \
    "$HOME/.config/Code/User/keybindings.json" \
    "$HOME/.config/Code/User/extensions.txt"
  do
    if [ -f "$file" ]; then
      health_ok "$file"
    else
      health_missing "$file"
    fi
  done

  health_section "Bootstrap scripts"

  local found_bootstrap_script=false

  for file in "$HOME"/bootstrap/install*.sh; do
    [ -e "$file" ] || continue

    found_bootstrap_script=true

    if [ -x "$file" ]; then
      health_ok "executable: $file"
    else
      health_warn "not executable: $file"
    fi
  done

  if [ "$found_bootstrap_script" = false ]; then
    health_missing "no bootstrap install scripts found"
  fi
}