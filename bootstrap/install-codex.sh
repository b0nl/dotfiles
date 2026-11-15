#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing or updating Codex CLI"

codex_installer_tmp="$(mktemp)"
trap 'rm -f "$codex_installer_tmp"' EXIT

curl --fail --location --silent --show-error \
  --proto '=https' --proto-redir '=https' --retry 3 \
  --connect-timeout 15 --max-time 300 \
  https://chatgpt.com/codex/install.sh \
  --output "$codex_installer_tmp"

# Install only; sign in separately after bootstrap.
CODEX_NON_INTERACTIVE=1 sh "$codex_installer_tmp"
