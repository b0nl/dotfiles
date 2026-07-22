#!/usr/bin/env bash

# ------------------------------------------------------------
# Dotfiles health check
# ------------------------------------------------------------

_dotfiles_health_green="\033[0;32m"
_dotfiles_health_red="\033[0;31m"
_dotfiles_health_yellow="\033[0;33m"
_dotfiles_health_blue="\033[0;34m"
_dotfiles_health_reset="\033[0m"

health_ok() {
  printf '%bOK%b: %s\n' \
    "$_dotfiles_health_green" \
    "$_dotfiles_health_reset" \
    "$*"
}

health_missing() {
  printf '%bMISSING%b: %s\n' \
    "$_dotfiles_health_red" \
    "$_dotfiles_health_reset" \
    "$*"
}

health_warn() {
  printf '%bWARN%b: %s\n' \
    "$_dotfiles_health_yellow" \
    "$_dotfiles_health_reset" \
    "$*"
}

health_section() {
  printf '\n%b==> %s%b\n' \
    "$_dotfiles_health_blue" \
    "$*" \
    "$_dotfiles_health_reset"
}

_dotfiles_health_current_shell_has_group() {
  local group_name="$1"

  id -nG 2>/dev/null |
    tr ' ' '\n' |
    grep -qx "$group_name"
}

_dotfiles_health_user_has_group() {
  local user_name="$1"
  local group_name="$2"

  id -nG "$user_name" 2>/dev/null |
    tr ' ' '\n' |
    grep -qx "$group_name"
}

_dotfiles_health_machine() {
  /usr/bin/git \
    --git-dir="$HOME/.dotfiles" \
    config --local --get dotfiles.machine 2>/dev/null || true
}

dotfiles-health() {
  local machine=""
  local cmd=""
  local file=""
  local user_name=""
  local kubectl_context=""
  local found_bootstrap_script=false
  local docker_config_dir=""
  local docker_config_file=""
  local work_registry="hub.braincreators.com"

  user_name="${USER:-$(id -un)}"
  docker_config_dir="${DOCKER_CONFIG:-$HOME/.docker}"
  docker_config_file="$docker_config_dir/config.json"

  health_section "Dotfiles"

  if type dotfiles >/dev/null 2>&1; then
    health_ok "dotfiles function available"

    if ! dotfiles status -sb; then
      health_warn "dotfiles status failed"
    fi
  else
    health_missing "dotfiles function not available"
  fi

  health_section "Machine type"

  machine="$(_dotfiles_health_machine)"

  case "$machine" in
    work|personal)
      health_ok "dotfiles.machine = $machine"
      ;;
    "")
      health_missing "dotfiles.machine is not configured"
      health_warn \
        "Run: dotfiles config --local dotfiles.machine work"
      health_warn \
        "Or:  dotfiles config --local dotfiles.machine personal"
      ;;
    *)
      health_warn "invalid dotfiles.machine value: $machine"
      ;;
  esac

  health_section "Core commands"

  for cmd in git curl uv code zotero xpad proton-authenticator; do
    if command -v "$cmd" >/dev/null 2>&1; then
      health_ok "$cmd -> $(command -v "$cmd")"
    else
      health_missing "$cmd"
    fi
  done

  health_section "Docker"

  if command -v docker >/dev/null 2>&1; then
    health_ok "docker -> $(command -v docker)"

    if _dotfiles_health_user_has_group "$user_name" docker; then
      health_ok "$user_name is configured in the docker group"
    else
      health_missing "$user_name is not configured in the docker group"
    fi

    if _dotfiles_health_current_shell_has_group docker; then
      health_ok "docker group is active in the current shell"
    else
      health_warn \
        "docker group is not active; log out and back in or run: newgrp docker"
    fi

    if docker info >/dev/null 2>&1; then
      health_ok "Docker daemon is accessible as the current user"
    else
      health_warn "Docker daemon is not accessible as the current user"
    fi
  else
    health_missing "docker"
  fi

  if [ "$machine" = "work" ]; then
    health_section "Work setup"

    if command -v kubectl >/dev/null 2>&1; then
      health_ok "kubectl -> $(command -v kubectl)"

      kubectl_context="$(
        kubectl config current-context 2>/dev/null || true
      )"

      if [ -n "$kubectl_context" ]; then
        health_ok "kubectl context = $kubectl_context"
      else
        health_warn "No kubectl context is currently configured"
      fi
    else
      health_missing "kubectl"
    fi

    if [ -r "$docker_config_file" ] &&
      grep -Fq -- "$work_registry" "$docker_config_file"; then
      health_ok "Docker login entry exists for $work_registry"
    else
      health_missing "Docker login entry missing for $work_registry"
      health_warn "Run: docker login $work_registry"
    fi
  fi

  if [ "$machine" = "personal" ]; then
    health_section "Personal setup"

    if command -v ledger-wallet >/dev/null 2>&1; then
      health_ok "ledger-wallet -> $(command -v ledger-wallet)"
    else
      health_missing "ledger-wallet"
      health_warn "Run: ~/bootstrap/install-ledger-wallet.sh"
    fi

    if [ -r /etc/udev/rules.d/20-ledger.rules ]; then
      health_ok "Ledger USB rules installed"
    else
      health_missing "/etc/udev/rules.d/20-ledger.rules"
    fi
  fi

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

  health_section "NZBridge"

  if [ -r "$HOME/.local/share/nzbridge/version" ]; then
      health_ok \
          "NZBridge assets prepared: v$(cat "$HOME/.local/share/nzbridge/version")"
  else
      health_missing "NZBridge prepared version"
      health_warn "Run: ~/bootstrap/install-nzbridge.sh"
  fi

  if [ -f "$HOME/.local/share/nzbridge/nz-bridge.xpi" ]; then
      health_ok "NZBridge Zotero plugin installer is available"
  else
      health_missing "$HOME/.local/share/nzbridge/nz-bridge.xpi"
  fi

  if [ -f "$HOME/.local/share/nzbridge/browser-extension/manifest.json" ]; then
      health_ok "NZBridge browser extension files are available"
  else
      health_missing \
          "$HOME/.local/share/nzbridge/browser-extension/manifest.json"
  fi

  if curl \
      --fail \
      --silent \
      --show-error \
      --max-time 2 \
      --header "Zotero-Allowed-Request: true" \
      "http://localhost:23119/n2z/status" \
      >/dev/null 2>&1
  then
      health_ok "NZBridge Zotero endpoint is reachable"
  else
      health_warn \
          "NZBridge endpoint is unavailable; start Zotero and verify the plugin"
  fi
}
