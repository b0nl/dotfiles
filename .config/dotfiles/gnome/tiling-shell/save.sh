#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
    pwd
)"
readonly DCONF_KEY="/org/gnome/shell/extensions/tilingshell/layouts-json"
readonly OUTPUT_FILE="$SCRIPT_DIR/layouts.json"

if ! command -v dconf >/dev/null 2>&1; then
    printf 'WARN: dconf is unavailable; Tiling Shell layouts were not saved\n' >&2
    exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
    printf 'WARN: python3 is unavailable; Tiling Shell layouts were not saved\n' >&2
    exit 0
fi

raw_value="$(dconf read "$DCONF_KEY" 2>/dev/null || true)"

if [[ -z "$raw_value" ]]; then
    printf 'WARN: No Tiling Shell layouts were found\n' >&2
    exit 0
fi

RAW_VALUE="$raw_value" python3 - "$OUTPUT_FILE" <<'PY'
import ast
import json
import os
import pathlib
import sys

output_path = pathlib.Path(sys.argv[1])
raw_value = os.environ["RAW_VALUE"]

layouts_json = ast.literal_eval(raw_value)
layouts = json.loads(layouts_json)

if not isinstance(layouts, list):
    raise SystemExit("Tiling Shell layouts must be a JSON array")

temporary_path = output_path.with_suffix(".json.tmp")
temporary_path.write_text(
    json.dumps(layouts, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
temporary_path.replace(output_path)

print(f"Saved {len(layouts)} Tiling Shell layout(s) to {output_path}")
PY
