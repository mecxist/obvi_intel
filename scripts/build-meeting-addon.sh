#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v swiftc >/dev/null || { echo "swiftc is required"; exit 1; }
command -v lipo >/dev/null || { echo "lipo is required"; exit 1; }

SOURCE="addons/meeting-capture-intel/Sources/MeetingCaptureIntel/main.swift"
OUTPUT_DIR="addons/meeting-capture-intel/bin"
OUTPUT="$OUTPUT_DIR/obvious-intel-meeting-capture"

mkdir -p "$OUTPUT_DIR"

swiftc \
  -O \
  -target x86_64-apple-macosx13.0 \
  "$SOURCE" \
  -o "$OUTPUT" \
  -framework AppKit \
  -framework AVFoundation \
  -framework CoreGraphics \
  -framework CoreMedia \
  -framework ScreenCaptureKit

ARCHS="$(lipo -archs "$OUTPUT")"
case " $ARCHS " in
  *" x86_64 "*) ;;
  *) echo "Expected x86_64 helper, got: $ARCHS"; exit 1 ;;
esac

chmod +x "$OUTPUT"
codesign --force --sign - "$OUTPUT" >/dev/null 2>&1 || true

echo "Built Intel meeting capture helper:"
echo "$OUTPUT"
file "$OUTPUT"
