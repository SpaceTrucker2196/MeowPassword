#!/usr/bin/env bash
# make_dmg.sh — wrap MeowPassword.app in a distributable .dmg.
#
# Assumes ./build_app.sh has already produced MeowPassword.app.
# Produces MeowPassword-<version>.dmg with a "drag to Applications" install layout.
#
# Usage:
#   ./make_dmg.sh                        # picks version from Info.plist
#   VERSION=1.2.3 ./make_dmg.sh          # override version

set -euo pipefail

APP_NAME="MeowPassword"
APP_DIR="${APP_NAME}.app"

if [[ ! -d "$APP_DIR" ]]; then
    echo "ERROR: $APP_DIR not found. Run ./build_app.sh first." >&2
    exit 1
fi

if [[ -z "${VERSION:-}" ]]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_DIR/Contents/Info.plist" 2>/dev/null || echo "0.0.0")
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
STAGE_DIR=$(mktemp -d)
trap 'rm -rf "$STAGE_DIR"' EXIT

echo "Staging DMG contents in $STAGE_DIR..."
cp -R "$APP_DIR" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

# Optional background image — skipped if it doesn't exist.
BG_SRC="dmg_background.png"
if [[ -f "$BG_SRC" ]]; then
    mkdir -p "$STAGE_DIR/.background"
    cp "$BG_SRC" "$STAGE_DIR/.background/background.png"
fi

echo "Creating $DMG_NAME..."
rm -f "$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DMG_NAME"

# Sign the DMG. Use CODESIGN_IDENTITY if provided (e.g. Developer ID); else ad-hoc.
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$DMG_NAME"
else
    codesign --force --sign - "$DMG_NAME" 2>/dev/null || true
fi

echo
echo "Built $DMG_NAME"
echo "  size: $(du -h "$DMG_NAME" | cut -f1)"
