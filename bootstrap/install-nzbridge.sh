#!/usr/bin/env bash

set -euo pipefail

VERSION="0.4.2"

REPOSITORY="Rafael-Silva-Oliveira/NZBridge"
RELEASE_BASE_URL="https://github.com/$REPOSITORY/releases/download/v$VERSION"

XPI_NAME="nz-bridge.xpi"
BROWSER_ZIP_NAME="NZBridge-browser-extension-v$VERSION.zip"

XPI_SHA256="46df6e5f1b562121fc5153882758b21c59777f703e19688251314d8ad278b466"
BROWSER_ZIP_SHA256="7a5c4cabb00b1bd34ae8c80daae1ad62380273a24d09484657d3c350f62be9ba"

INSTALL_DIR="$HOME/.local/share/nzbridge"
XPI_PATH="$INSTALL_DIR/$XPI_NAME"
BROWSER_DIR="$INSTALL_DIR/browser-extension"
VERSION_FILE="$INSTALL_DIR/version"

for command_name in curl unzip sha256sum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: Required command is missing: $command_name"
        exit 1
    fi
done

if
    [ -r "$VERSION_FILE" ] &&
    [ "$(cat "$VERSION_FILE")" = "$VERSION" ] &&
    [ -f "$XPI_PATH" ] &&
    [ -f "$BROWSER_DIR/manifest.json" ]
then
    echo "==> NZBridge v$VERSION is already prepared"
else
    echo "==> Downloading NZBridge v$VERSION"

    temporary_dir="$(mktemp -d)"
    trap 'rm -rf "$temporary_dir"' EXIT

    xpi_download="$temporary_dir/$XPI_NAME"
    browser_download="$temporary_dir/$BROWSER_ZIP_NAME"
    extract_dir="$temporary_dir/browser-extension"

    curl \
        --fail \
        --location \
        --retry 3 \
        --output "$xpi_download" \
        "$RELEASE_BASE_URL/$XPI_NAME"

    curl \
        --fail \
        --location \
        --retry 3 \
        --output "$browser_download" \
        "$RELEASE_BASE_URL/$BROWSER_ZIP_NAME"

    echo "==> Verifying NZBridge downloads"

    (
        cd "$temporary_dir"

        printf '%s  %s\n' \
            "$XPI_SHA256" \
            "$XPI_NAME" |
            sha256sum --check -

        printf '%s  %s\n' \
            "$BROWSER_ZIP_SHA256" \
            "$BROWSER_ZIP_NAME" |
            sha256sum --check -
    )

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
        echo "ERROR: Browser extension manifest.json was not found"
        exit 1
    fi

    extension_source_dir="$(dirname "$manifest_path")"
    extension_staging_dir="$INSTALL_DIR/.browser-extension.new"

    mkdir -p "$INSTALL_DIR"
    install -m 0644 "$xpi_download" "$XPI_PATH"

    rm -rf "$extension_staging_dir"
    mkdir -p "$extension_staging_dir"
    cp -a "$extension_source_dir/." "$extension_staging_dir/"

    rm -rf "$BROWSER_DIR"
    mv "$extension_staging_dir" "$BROWSER_DIR"

    printf '%s\n' "$VERSION" > "$VERSION_FILE"

    echo "==> NZBridge v$VERSION prepared"
fi

cat <<EOF

Manual setup is required once:

1. Zotero:
   Tools -> Plugins -> gear icon -> Install Plugin From File
   Select:
   $XPI_PATH

2. Chrome:
   Open chrome://extensions
   Enable Developer mode
   Choose Load unpacked
   Select:
   $BROWSER_DIR

3. Chrome local access:
   NZBridge -> Details -> Site settings
   Set Local network access to Allow

4. Keep NotebookLM's interface language set to English.

EOF