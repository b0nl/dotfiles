#!/usr/bin/env bash

set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo "==> Zotero installation skipped: apt is not available"
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "==> Zotero installation skipped: curl is not available"
    exit 0
fi

case "$(uname -m)" in
    x86_64 | aarch64 | arm64 | i386 | i686)
        ;;
    *)
        echo "==> Zotero installation skipped: unsupported architecture $(uname -m)"
        exit 0
        ;;
esac

KEYRING="/usr/share/keyrings/zotero-archive-keyring.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/zotero.list"

KEY_URL="https://raw.githubusercontent.com/retorquere/zotero-pkg/master/zotero-archive-keyring.gpg"
REPOSITORY_URL="https://zotero.retorque.re/file/apt-package-archive"

echo "==> Configuring Zotero apt repository"

temporary_key="$(mktemp)"
trap 'rm -f "$temporary_key"' EXIT

curl -fsSL "$KEY_URL" -o "$temporary_key"

sudo install -d -m 0755 /usr/share/keyrings
sudo install -m 0644 "$temporary_key" "$KEYRING"

# Avoid duplicate definitions if the upstream installer was previously used
sudo rm -f /etc/apt/sources.list.d/zotero.sources

printf 'deb [signed-by=%s by-hash=force] %s ./\n' \
    "$KEYRING" \
    "$REPOSITORY_URL" |
    sudo tee "$SOURCE_FILE" >/dev/null

echo "==> Installing Zotero"

sudo apt update
sudo apt install -y zotero

echo "==> Zotero installation complete"
