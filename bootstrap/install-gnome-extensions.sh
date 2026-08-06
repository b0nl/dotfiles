#!/usr/bin/env bash

set -euo pipefail

readonly EXTENSION_ID="7065"
readonly EXTENSIONS_BASE_URL="https://extensions.gnome.org"
readonly UBUNTU_TILING_UUID="tiling-assistant@ubuntu.com"
readonly TILING_SHELL_UUID="tilingshell@ferrarodomenico.com"

info() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'WARN: %s\n' "$*" >&2
}

if ! command -v gnome-shell >/dev/null 2>&1; then
    warn "GNOME Shell is not installed; skipping GNOME extensions"
    exit 0
fi

if ! command -v gnome-extensions >/dev/null 2>&1; then
    warn "gnome-extensions is unavailable; skipping Tiling Shell"
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    warn "python3 is required to resolve the compatible extension release"
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    warn "curl is required to download Tiling Shell"
    exit 1
fi

gnome_major_version="$(
    gnome-shell --version |
        grep -oE '[0-9]+' |
        head -n 1
)"

if [[ -z "$gnome_major_version" ]]; then
    warn "Could not determine the installed GNOME Shell version"
    exit 1
fi

info "Detected GNOME Shell ${gnome_major_version}"

api_url="${EXTENSIONS_BASE_URL}/extension-info/?pk=${EXTENSION_ID}&shell_version=${gnome_major_version}"

download_url="$(
    python3 - "$api_url" "$EXTENSIONS_BASE_URL" <<'PY'
import json
import sys
import urllib.parse
import urllib.request

api_url = sys.argv[1]
base_url = sys.argv[2]

request = urllib.request.Request(
    api_url,
    headers={"User-Agent": "dotfiles-bootstrap"},
)

with urllib.request.urlopen(request, timeout=30) as response:
    metadata = json.load(response)

download_url = metadata.get("download_url")

if not download_url:
    raise SystemExit(
        "No compatible Tiling Shell release was found for this GNOME version"
    )

print(urllib.parse.urljoin(base_url, download_url))
PY
)"

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

archive_path="$temporary_directory/tiling-shell.zip"

info "Downloading Tiling Shell"
curl --fail --location --silent --show-error \
    "$download_url" \
    --output "$archive_path"

info "Installing Tiling Shell"
gnome-extensions install --force "$archive_path"

if gnome-extensions list 2>/dev/null |
    grep -qxF "$UBUNTU_TILING_UUID"; then
    info "Disabling Ubuntu Tiling Assistant to avoid conflicts"

    if ! gnome-extensions disable "$UBUNTU_TILING_UUID"; then
        warn "Could not disable Ubuntu Tiling Assistant"
    fi
fi

if gnome-extensions enable "$TILING_SHELL_UUID" 2>/dev/null; then
    info "Tiling Shell enabled"
else
    warn "Tiling Shell was installed but could not be enabled"
    warn "Log out and back in, then run:"
    warn "gnome-extensions enable ${TILING_SHELL_UUID}"
fi