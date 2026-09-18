#!/usr/bin/env bash
set -euo pipefail

DEFAULT_DIR="${HOME}/.local/share/obvious-intel/tacet"
TACET_DIR="${TACET_DIR:-$DEFAULT_DIR}"

if [[ ! -d "$TACET_DIR" ]]; then
  echo "Tacet is not installed at $TACET_DIR"
  echo "Run ./scripts/setup-tacet.sh first."
  exit 1
fi

cd "$TACET_DIR"

if [[ -f ".venv/bin/activate" ]]; then
  source .venv/bin/activate
fi

if [[ -f "Makefile" ]]; then
  exec make app
fi

echo "Could not find Tacet's app launcher."
exit 1
