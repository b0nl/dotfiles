#!/usr/bin/env bash

set -euo pipefail

VERSION_URL="https://proton.me/download/authenticator/linux/version.json"

for command_name in curl python3 sha512sum dpkg-deb apt-get; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "==> Proton Authenticator installation skipped: $command_name is unavailable"
        exit 0
    fi
done

architecture="$(dpkg --print-architecture)"

if [ "$architecture" != "amd64" ]; then
    echo "==> Proton Authenticator installation skipped: unsupported architecture $architecture"
    exit 0
fi

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

metadata_file="$temporary_dir/version.json"

echo "==> Fetching Proton Authenticator release metadata"
curl -fsSL "$VERSION_URL" -o "$metadata_file"

mapfile -t release_info < <(
    python3 - "$metadata_file" <<'PY'
import json
import sys
from pathlib import Path

metadata = json.loads(Path(sys.argv[1]).read_text())

for release in metadata.get("Releases", []):
    for package in release.get("File", []):
        if package.get("Identifier") == ".deb (Ubuntu/Debian)":
            print(release["Version"])
            print(package["Url"])
            print(package["Sha512CheckSum"])
            raise SystemExit(0)

raise SystemExit("No Ubuntu/Debian Proton Authenticator release found")
PY
)

if [ "${#release_info[@]}" -ne 3 ]; then
    echo "ERROR: Could not determine the latest Proton Authenticator release"
    exit 1
fi

release_version="${release_info[0]}"
download_url="${release_info[1]}"
expected_checksum="${release_info[2]}"
deb_file="$temporary_dir/ProtonAuthenticator.deb"

echo "==> Downloading Proton Authenticator $release_version"
curl -fsSL "$download_url" -o "$deb_file"

echo "==> Verifying Proton Authenticator package"
printf '%s  %s\n' "$expected_checksum" "$deb_file" |
    sha512sum --check -

package_name="$(dpkg-deb -f "$deb_file" Package)"
package_version="$(dpkg-deb -f "$deb_file" Version)"
installed_version="$(
    dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null || true
)"

if [ "$installed_version" = "$package_version" ]; then
    echo "==> Proton Authenticator $package_version is already installed"
    exit 0
fi

echo "==> Installing Proton Authenticator $package_version"
sudo apt-get install -y "$deb_file"

echo "==> Proton Authenticator installation complete"
