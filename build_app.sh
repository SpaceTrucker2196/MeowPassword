#!/usr/bin/env bash
# build_app.sh — build MeowPassword.app bundle around the SwiftPM binaries.
#
# Produces ./MeowPassword.app with:
#   Contents/MacOS/MeowPasswordApp   (SwiftUI app, main entry)
#   Contents/MacOS/meowpass          (bundled CLI — the app shells out to it)
#   Contents/Info.plist              (URL scheme, Services, bundle metadata)
#   Contents/Resources/Info.plist    (SwiftPM resource bundle)
#
# Run:
#   ./build_app.sh
#   open MeowPassword.app
#
# Also wraps the app in a drag-to-Applications installer DMG via
# ./make_dmg.sh. Set SKIP_DMG=1 to skip that step (CI does — it builds
# its DMG separately, after Developer ID signing and notarization).
#
# The Services menu registers the first time the app runs.
# Grant it clipboard/automation access via System Settings → Privacy on first run.

set -euo pipefail

CONFIG="${CONFIG:-release}"
APP_NAME="MeowPassword"
APP_DIR="${APP_NAME}.app"

echo "Building ($CONFIG)..."
swift build -c "$CONFIG" --product meowpass
swift build -c "$CONFIG" --product MeowPasswordApp

BIN_DIR=".build/$CONFIG"
APP_BINARY="$BIN_DIR/MeowPasswordApp"
CLI_BINARY="$BIN_DIR/meowpass"

if [[ ! -x "$APP_BINARY" ]]; then
    echo "ERROR: SwiftPM did not produce $APP_BINARY" >&2
    exit 1
fi
if [[ ! -x "$CLI_BINARY" ]]; then
    echo "ERROR: SwiftPM did not produce $CLI_BINARY" >&2
    exit 1
fi

echo "Assembling $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$APP_BINARY" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$CLI_BINARY" "$APP_DIR/Contents/MacOS/meowpass"
cp Sources/MeowPasswordApp/Resources/Info.plist "$APP_DIR/Contents/Info.plist"

# Copy SwiftPM-generated resource bundle (contains hero_cat.png etc).
for bundle in "$BIN_DIR"/*_MeowPasswordApp.bundle; do
    if [[ -e "$bundle" ]]; then
        cp -R "$bundle" "$APP_DIR/Contents/Resources/"
    fi
done

# Also drop loose assets directly into Contents/Resources so Bundle.main
# lookups work without depending on SwiftPM's module bundle plumbing.
if [[ -d Sources/MeowPasswordApp/Assets ]]; then
    cp Sources/MeowPasswordApp/Assets/*.png "$APP_DIR/Contents/Resources/" 2>/dev/null || true
    cp Sources/MeowPasswordApp/Assets/*.jpg "$APP_DIR/Contents/Resources/" 2>/dev/null || true
    cp Sources/MeowPasswordApp/Assets/AppIcon.icns "$APP_DIR/Contents/Resources/" 2>/dev/null || true
fi

# Point CFBundleExecutable at our renamed binary.
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$APP_DIR/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP_NAME" "$APP_DIR/Contents/Info.plist"

# Ad-hoc sign so Launch Services / Gatekeeper accepts the local build.
# Entitlements are only applied when a real signing identity is set (from CI);
# ad-hoc signatures ignore them.
ENTITLEMENTS_FILE="Sources/MeowPasswordApp/Resources/MeowPassword.entitlements"
if [[ -n "${CODESIGN_IDENTITY:-}" && -f "$ENTITLEMENTS_FILE" ]]; then
    codesign --force --deep --options runtime --timestamp \
        --entitlements "$ENTITLEMENTS_FILE" \
        --sign "$CODESIGN_IDENTITY" \
        "$APP_DIR"
else
    codesign --force --deep --sign - "$APP_DIR"
fi

echo
echo "Built $APP_DIR"
echo "Open with: open $APP_DIR"
echo "Register Services immediately: /System/Library/CoreServices/pbs -update"

if [[ "${SKIP_DMG:-0}" != "1" ]]; then
    echo
    ./make_dmg.sh
fi
