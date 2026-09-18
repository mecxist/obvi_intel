#!/usr/bin/env bash
set -euo pipefail

TACET_REPO="https://github.com/Tacetapp/tacet.git"
DEFAULT_DIR="${HOME}/.local/share/obvious-intel/tacet"
TACET_DIR="${TACET_DIR:-$DEFAULT_DIR}"

mkdir -p "$(dirname "$TACET_DIR")"

if [[ -d "$TACET_DIR/.git" ]]; then
  echo "Updating Tacet in $TACET_DIR"
  git -C "$TACET_DIR" pull --ff-only
else
  echo "Cloning Tacet into $TACET_DIR"
  git clone "$TACET_REPO" "$TACET_DIR"
fi

echo
echo "Tacet is available at:"
echo "$TACET_DIR"
echo
echo "Run Tacet's setup:"
echo "  cd "$TACET_DIR""
echo "  ./setup.sh"
echo
echo "After setup, launch it with:"
echo "  ./scripts/run-tacet.sh"
