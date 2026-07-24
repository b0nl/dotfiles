#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
    pwd
)"
readonly DCONF_KEY="/org/gnome/shell/extensions/tilingshell/layouts-json"
readonly INPUT_FILE="$SCRIPT_DIR/layouts.json"

if ! command -v dconf >/dev/null 2>&1; then
    printf 'WARN: dconf is unavailable; Tiling Shell layouts were not restored\n' >&2
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    printf 'WARN: python3 is unavailable; Tiling Shell layouts were not restored\n' >&2
    exit 0
fi

if [[ ! -s "$INPUT_FILE" ]]; then
    printf 'WARN: No tracked Tiling Shell layouts found at %s\n' \
        "$INPUT_FILE" >&2
    exit 0
fi

variant_value="$(
    python3 - "$INPUT_FILE" <<'PY'
import json
import pathlib
import sys

input_path = pathlib.Path(sys.argv[1])
layouts = json.loads(input_path.read_text(encoding="utf-8"))

if not isinstance(layouts, list):
    raise SystemExit("Tiling Shell layouts must be a JSON array")

compact_json = json.dumps(
    layouts,
    separators=(",", ":"),
    ensure_ascii=False,
)

print(repr(compact_json))
PY
)"

dconf write "$DCONF_KEY" "$variant_value"

printf 'Restored Tiling Shell layouts from %s\n' "$INPUT_FILE"
