#!/usr/bin/env bash
set -euo pipefail

if dpkg-query -W -f='${db:Status-Status}\n' chatgpt 2>/dev/null |
  grep -qx installed; then
  echo "==> ChatGPT desktop is already installed; updates are managed by APT"
  exit 0
fi

chatgpt_arch="$(dpkg --print-architecture)"
case "$chatgpt_arch" in
  amd64|arm64) ;;
  *) echo "ERROR: Unsupported ChatGPT architecture: $chatgpt_arch" >&2; exit 1 ;;
esac

chatgpt_tmp_dir="$(mktemp -d /tmp/steward-chatgpt.XXXXXX)"
trap 'rm -rf "$chatgpt_tmp_dir"' EXIT
chatgpt_deb="$chatgpt_tmp_dir/chatgpt.deb"

echo "==> Installing ChatGPT desktop, including Codex"
curl --fail --location --silent --show-error \
  --proto '=https' --proto-redir '=https' --retry 3 \
  --connect-timeout 15 --max-time 900 \
  "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_$chatgpt_arch.deb" \
  --output "$chatgpt_deb"

if [ "$(dpkg-deb -f "$chatgpt_deb" Package)" != chatgpt ] ||
   [ "$(dpkg-deb -f "$chatgpt_deb" Architecture)" != "$chatgpt_arch" ]; then
  echo "ERROR: Download is not the expected ChatGPT package." >&2
  exit 1
fi

# Let APT's restricted user read this public installer package.
chmod 0755 "$chatgpt_tmp_dir"
chmod 0644 "$chatgpt_deb"
sudo apt-get install -y "$chatgpt_deb"
