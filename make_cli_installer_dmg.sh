#!/usr/bin/env bash
# make_cli_installer_dmg.sh — wrap the meowpass-<version>.pkg installer
# in a DMG so users can double-click a single file.
#
# Assumes make_cli_pkg.sh has already produced meowpass-<version>.pkg.
#
# Usage:
#   ./make_cli_installer_dmg.sh
#   VERSION=1.2.3 ./make_cli_installer_dmg.sh

set -euo pipefail

CLI_NAME="meowpass"

if [[ -z "${VERSION:-}" ]]; then
    if [[ -f MeowPassword.app/Contents/Info.plist ]]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" MeowPassword.app/Contents/Info.plist)
    else
        VERSION="0.0.0"
    fi
fi

PKG="${CLI_NAME}-${VERSION}.pkg"
DMG="${CLI_NAME}-CLI-Installer-${VERSION}.dmg"

if [[ ! -f "$PKG" ]]; then
    echo "ERROR: $PKG not found. Run ./make_cli_pkg.sh first." >&2
    exit 1
fi

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# The DMG contains just the .pkg — double-clicking launches Installer.
cp "$PKG" "$STAGE/"

rm -f "$DMG"
hdiutil create \
    -volname "meowpass CLI" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DMG"

# Sign the DMG for Gatekeeper. Same identity as the app.
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign --force --timestamp --sign "$CODESIGN_IDENTITY" "$DMG"
else
    codesign --force --sign - "$DMG" 2>/dev/null || true
fi

echo
echo "Built $DMG"
echo "  size: $(du -h "$DMG" | cut -f1)"
