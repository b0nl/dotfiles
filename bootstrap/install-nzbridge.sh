#!/usr/bin/env bash

set -euo pipefail

REPOSITORY="Rafael-Silva-Oliveira/NZBridge"
API_BASE_URL="https://api.github.com/repos/$REPOSITORY/releases"
INSTALL_DIR="$HOME/.local/share/nzbridge"
XPI_NAME="nz-bridge.xpi"
XPI_PATH="$INSTALL_DIR/$XPI_NAME"
BROWSER_DIR="$INSTALL_DIR/browser-extension"
VERSION_FILE="$INSTALL_DIR/version"

force=false
check_only=false

usage() {
    cat <<'USAGE'
Usage: install-nzbridge.sh [--check] [--force]

Options:
  --check  Report whether a newer NZBridge release is available.
  --force  Re-download and reinstall the selected release.
  -h, --help
           Show this help.

Environment:
  NZBRIDGE_VERSION=0.4.3
           Install a specific release instead of the latest release.
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --check)
            check_only=true
            ;;
        --force)
            force=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

for command_name in curl unzip sha256sum python3; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: Required command is missing: $command_name" >&2
        exit 1
    fi
done

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

requested_version="${NZBRIDGE_VERSION:-latest}"
if [ "$requested_version" = "latest" ]; then
    release_api_url="$API_BASE_URL/latest"
else
    requested_version="${requested_version#v}"
    release_api_url="$API_BASE_URL/tags/v$requested_version"
fi

release_json="$temporary_dir/release.json"

echo "==> Resolving NZBridge release metadata"
curl \
    --fail \
    --location \
    --retry 3 \
    --silent \
    --show-error \
    --header "Accept: application/vnd.github+json" \
    --header "User-Agent: b0nl-dotfiles-nzbridge-installer" \
    --output "$release_json" \
    "$release_api_url"

mapfile -t release_metadata < <(
    python3 - "$release_json" <<'PY'
import json
import re
import sys

release_path = sys.argv[1]
with open(release_path, encoding="utf-8") as release_file:
    release = json.load(release_file)

tag = release.get("tag_name")
assets = release.get("assets", [])

if not isinstance(tag, str) or not tag:
    raise SystemExit("ERROR: GitHub release metadata has no tag_name")

version = tag.removeprefix("v")
expected_browser_name = f"NZBridge-browser-extension-v{version}.zip"

xpi_asset = next(
    (asset for asset in assets if asset.get("name") == "nz-bridge.xpi"),
    None,
)

browser_asset = next(
    (asset for asset in assets if asset.get("name") == expected_browser_name),
    None,
)
if browser_asset is None:
    browser_asset = next(
        (
            asset
            for asset in assets
            if re.fullmatch(
                r"NZBridge-browser-extension-v?.+\.zip",
                str(asset.get("name", "")),
                flags=re.IGNORECASE,
            )
        ),
        None,
    )

if xpi_asset is None:
    raise SystemExit("ERROR: nz-bridge.xpi is missing from the release")
if browser_asset is None:
    raise SystemExit("ERROR: Browser-extension ZIP is missing from the release")

for asset in (xpi_asset, browser_asset):
    url = asset.get("browser_download_url")
    digest = asset.get("digest")

    if not isinstance(url, str) or not url.startswith("https://github.com/"):
        raise SystemExit(f"ERROR: Invalid download URL for {asset.get('name')}")
    if not isinstance(digest, str) or not re.fullmatch(r"sha256:[0-9a-fA-F]{64}", digest):
        raise SystemExit(f"ERROR: GitHub supplied no usable SHA-256 digest for {asset.get('name')}")

values = (
    tag,
    xpi_asset["name"],
    xpi_asset["browser_download_url"],
    xpi_asset["digest"],
    browser_asset["name"],
    browser_asset["browser_download_url"],
    browser_asset["digest"],
)

for value in values:
    print(value)
PY
)

if [ "${#release_metadata[@]}" -ne 7 ]; then
    echo "ERROR: Could not parse NZBridge release metadata" >&2
    exit 1
fi

TAG_NAME="${release_metadata[0]}"
VERSION="${TAG_NAME#v}"
XPI_ASSET_NAME="${release_metadata[1]}"
XPI_DOWNLOAD_URL="${release_metadata[2]}"
XPI_DIGEST="${release_metadata[3]}"
BROWSER_ZIP_NAME="${release_metadata[4]}"
BROWSER_DOWNLOAD_URL="${release_metadata[5]}"
BROWSER_DIGEST="${release_metadata[6]}"

installed_version=""
if [ -r "$VERSION_FILE" ]; then
    installed_version="$(cat "$VERSION_FILE")"
fi

if $check_only; then
    if [ "$installed_version" = "$VERSION" ]; then
        echo "NZBridge v$VERSION is current"
    elif [ -n "$installed_version" ]; then
        echo "NZBridge update available: v$installed_version -> v$VERSION"
    else
        echo "NZBridge v$VERSION is available and is not installed"
    fi
    exit 0
fi

if \
    ! $force &&
    [ "$installed_version" = "$VERSION" ] &&
    [ -f "$XPI_PATH" ] &&
    [ -f "$BROWSER_DIR/manifest.json" ]
then
    echo "==> NZBridge v$VERSION is already prepared"
else
    echo "==> Downloading NZBridge v$VERSION"

    xpi_download="$temporary_dir/$XPI_ASSET_NAME"
    browser_download="$temporary_dir/$BROWSER_ZIP_NAME"
    extract_dir="$temporary_dir/browser-extension"

    curl \
        --fail \
        --location \
        --retry 3 \
        --silent \
        --show-error \
        --output "$xpi_download" \
        "$XPI_DOWNLOAD_URL"

    curl \
        --fail \
        --location \
        --retry 3 \
        --silent \
        --show-error \
        --output "$browser_download" \
        "$BROWSER_DOWNLOAD_URL"

    echo "==> Verifying NZBridge downloads"

    printf '%s  %s\n' \
        "${XPI_DIGEST#sha256:}" \
        "$xpi_download" |
        sha256sum --check -

    printf '%s  %s\n' \
        "${BROWSER_DIGEST#sha256:}" \
        "$browser_download" |
        sha256sum --check -

    mkdir -p "$extract_dir"
    unzip -q "$browser_download" -d "$extract_dir"

    manifest_path="$(
        find "$extract_dir" \
            -maxdepth 4 \
            -type f \
            -name manifest.json \
            -print \
            -quit
    )"

    if [ -z "$manifest_path" ]; then
        echo "ERROR: Browser extension manifest.json was not found" >&2
        exit 1
    fi

    extension_source_dir="$(dirname "$manifest_path")"
    extension_staging_dir="$INSTALL_DIR/.browser-extension.new"
    extension_backup_dir="$INSTALL_DIR/.browser-extension.old"
    xpi_staging_path="$INSTALL_DIR/.$XPI_NAME.new"
    version_staging_path="$INSTALL_DIR/.version.new"

    mkdir -p "$INSTALL_DIR"

    install -m 0644 "$xpi_download" "$xpi_staging_path"

    rm -rf "$extension_staging_dir" "$extension_backup_dir"
    mkdir -p "$extension_staging_dir"
    cp -a "$extension_source_dir/." "$extension_staging_dir/"

    if [ -e "$BROWSER_DIR" ]; then
        mv "$BROWSER_DIR" "$extension_backup_dir"
    fi

    if ! mv "$extension_staging_dir" "$BROWSER_DIR"; then
        if [ -e "$extension_backup_dir" ]; then
            mv "$extension_backup_dir" "$BROWSER_DIR"
        fi
        exit 1
    fi

    rm -rf "$extension_backup_dir"
    mv "$xpi_staging_path" "$XPI_PATH"
    printf '%s\n' "$VERSION" > "$version_staging_path"
    mv "$version_staging_path" "$VERSION_FILE"

    echo "==> NZBridge v$VERSION prepared"
fi

cat <<EOF

One-time/manual application steps:

1. Zotero:
   Tools -> Plugins -> gear icon -> Install Plugin From File
   Select:
   $XPI_PATH

2. Chrome or Edge:
   Open chrome://extensions or edge://extensions
   Enable Developer mode
   Load or reload the unpacked extension from:
   $BROWSER_DIR

3. Allow local-network access in the extension's site settings.

4. Keep NotebookLM's interface language set to English.

Future updates:
   ~/bootstrap/install-nzbridge.sh

Check without installing:
   ~/bootstrap/install-nzbridge.sh --check

EOF