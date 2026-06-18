#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing uv"

if command -v uv >/dev/null 2>&1; then
  echo "==> uv already installed: $(uv --version)"
  exit 0
fi

curl -LsSf https://astral.sh/uv/install.sh | sh

echo "==> uv installed"
echo "==> Restart your shell or run:"
echo "    source ~/.bashrc"