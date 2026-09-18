#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/build-meeting-addon.sh
./scripts/build-intel.sh

APP="src-tauri/target/x86_64-apple-darwin/release/bundle/macos/Obvious Intel.app"
HELPER="addons/meeting-capture-intel/bin/obvious-intel-meeting-capture"
DEST="$APP/Contents/Resources/obvious-intel-meeting-capture"
DMG="ObviousIntelWithMeetingCapture.dmg"

[[ -d "$APP" ]] || { echo "Obvious Intel.app was not found at $APP"; exit 1; }
[[ -f "$HELPER" ]] || { echo "Meeting capture helper was not built"; exit 1; }

mkdir -p "$APP/Contents/Resources"
cp "$HELPER" "$DEST"
chmod +x "$DEST"

codesign --force --sign - "$DEST" >/dev/null 2>&1 || true
codesign --force --deep --sign - "$APP"

rm -f "$DMG"
hdiutil create \
  -volname "Obvious Intel" \
  -srcfolder "$APP" \
  -ov \
  -format UDZO \
  "$DMG"

echo
echo "Built Obvious Intel with the optional Intel meeting capture add-on:"
echo "$APP"
echo "$DMG"
