#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

SOURCE_HELPER="addons/meeting-capture-intel/bin/obvious-intel-meeting-capture"
BUNDLED_HELPER="src-tauri/target/x86_64-apple-darwin/release/bundle/macos/Obvious Intel.app/Contents/Resources/obvious-intel-meeting-capture"

if [[ -x "$BUNDLED_HELPER" ]]; then
  HELPER="$BUNDLED_HELPER"
elif [[ -x "$SOURCE_HELPER" ]]; then
  HELPER="$SOURCE_HELPER"
else
  echo "Intel meeting capture helper is not built."
  echo "Run: ./scripts/build-meeting-addon.sh"
  exit 1
fi

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
  status)
    exec "$HELPER" status
    ;;
  permissions)
    exec "$HELPER" request-permissions
    ;;
  sources)
    exec "$HELPER" list-sources
    ;;
  record)
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 record SOURCE_ID OUTPUT_DIR [true|false]"
      echo "Example: $0 record 'window:1234' '$HOME/Desktop/obvious-recording' true"
      exit 1
    fi
    SOURCE_ID="$1"
    OUTPUT_DIR="$2"
    CAPTURE_MIC="${3:-true}"
    exec "$HELPER" record \
      --source-id "$SOURCE_ID" \
      --output-dir "$OUTPUT_DIR" \
      --capture-microphone "$CAPTURE_MIC"
    ;;
  *)
    echo "Usage: $0 {status|permissions|sources|record}"
    exit 1
    ;;
esac
