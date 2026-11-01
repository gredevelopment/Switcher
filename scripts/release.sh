#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "Usage: scripts/release.sh <version>   (example: 1.0.0)" >&2
  exit 1
fi

BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/Switcher.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP_PATH="$EXPORT_DIR/Switcher.app"
DMG_PATH="$BUILD_DIR/Switcher-${VERSION}.dmg"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Generating Xcode project…"
xcodegen generate

echo "Archiving Release…"
xcodebuild archive \
  -project Switcher.xcodeproj \
  -scheme Switcher \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM=TN65L8H2L8 \
  | xcbeautify 2>/dev/null || cat

echo "Exporting Developer ID build…"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT/ExportOptions.plist" \
  | xcbeautify 2>/dev/null || cat

if [[ ! -d "$APP_PATH" ]]; then
  echo "Export failed: $APP_PATH not found" >&2
  exit 1
fi

echo "Creating DMG…"
rm -f "$DMG_PATH"

create-dmg \
  --volname "Switcher" \
  --window-pos 200 120 \
  --window-size 560 320 \
  --icon-size 80 \
  --icon "Switcher.app" 140 160 \
  --hide-extension "Switcher.app" \
  --app-drop-link 420 160 \
  "$DMG_PATH" \
  "$APP_PATH" \
  || {
    echo "create-dmg failed; building DMG with hdiutil…"
    STAGING_DIR="$BUILD_DIR/dmg-staging"
    rm -rf "$STAGING_DIR"
    mkdir -p "$STAGING_DIR"
    cp -R "$APP_PATH" "$STAGING_DIR/"
    ln -s /Applications "$STAGING_DIR/Applications"
    hdiutil create -volname "Switcher" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
  }

echo "Done."
echo "App: $APP_PATH"
echo "DMG: $DMG_PATH"
