#!/usr/bin/env bash
set -euo pipefail

DMG="${1:-}"
if [[ -z "$DMG" || ! -f "$DMG" ]]; then
  echo "Usage: $0 /path/to/Obvious_0.34.1_aarch64.dmg"
  exit 1
fi

TMP="$(mktemp -d)"
MOUNT="$TMP/mount"
REPORT="${PWD}/obvious-official-report.txt"
mkdir -p "$MOUNT"
cleanup() {
  hdiutil detach "$MOUNT" -quiet 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

hdiutil attach "$DMG" -mountpoint "$MOUNT" -nobrowse -readonly >/dev/null
APP="$(find "$MOUNT" -maxdepth 2 -name '*.app' -type d | head -1)"
[[ -n "$APP" ]] || { echo "No .app found"; exit 1; }

{
  echo "# Obvious official app inspection"
  echo "APP=$APP"
  echo
  echo "## Info.plist"
  plutil -p "$APP/Contents/Info.plist" || true
  echo
  echo "## Main executable"
  EXE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist" 2>/dev/null || true)"
  EXE="$APP/Contents/MacOS/$EXE_NAME"
  echo "$EXE"
  file "$EXE" || true
  echo
  echo "## Entitlements"
  codesign -d --entitlements :- "$APP" 2>&1 || true
  echo
  echo "## Bundle signature"
  codesign -dv --verbose=4 "$APP" 2>&1 || true
  echo
  echo "## Mach-O architectures"
  find "$APP/Contents" -type f -print0 | while IFS= read -r -d '' f; do
    DESC="$(file "$f" 2>/dev/null || true)"
    case "$DESC" in
      *Mach-O*) echo "$DESC" ;;
    esac
  done
  echo
  echo "## Native/sidecar candidates"
  find "$APP/Contents" -type f \( -name '*.dylib' -o -name '*.node' -o -perm -111 \) -print | sort
  echo
  echo "## Recall files"
  find "$APP/Contents" -iname '*recall*' -o -path '*desktop-sdk*' | sort
  echo
  echo "## Top-level Resources"
  find "$APP/Contents/Resources" -maxdepth 3 -type f 2>/dev/null | sort | head -1000
} > "$REPORT"

echo "Wrote $REPORT"
