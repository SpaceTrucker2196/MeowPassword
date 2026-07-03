#!/usr/bin/env bash
# make_cli_pkg.sh — build a signed .pkg installer that drops `meowpass`
# into /usr/local/bin. Optionally signs with the Developer ID Installer
# identity in $CODESIGN_INSTALLER_IDENTITY.
#
# Requires: ./build_app.sh (or `swift build -c release --product meowpass`)
# to have already produced the CLI binary.
#
# Usage:
#   ./make_cli_pkg.sh                        # picks version from Info.plist
#   VERSION=1.2.3 ./make_cli_pkg.sh          # override version
#
# Outputs: meowpass-<version>.pkg

set -euo pipefail

CLI_NAME="meowpass"
IDENTIFIER="io.river.meowpass"
CONFIG="${CONFIG:-release}"

# Where the CLI binary lives after `swift build -c release`.
CLI_SRC=".build/${CONFIG}/${CLI_NAME}"
if [[ ! -x "$CLI_SRC" ]]; then
    echo "ERROR: $CLI_SRC missing. Run: swift build -c ${CONFIG} --product meowpass" >&2
    exit 1
fi

# Version — from the App's Info.plist if present, else default.
if [[ -z "${VERSION:-}" ]]; then
    if [[ -f MeowPassword.app/Contents/Info.plist ]]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" MeowPassword.app/Contents/Info.plist)
    else
        VERSION="0.0.0"
    fi
fi

PKG_NAME="${CLI_NAME}-${VERSION}.pkg"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# Staging layout: <root>/usr/local/bin/meowpass — pkgbuild lays it down
# at that literal path under / on the target.
mkdir -p "$STAGE/root/usr/local/bin"
cp "$CLI_SRC" "$STAGE/root/usr/local/bin/${CLI_NAME}"
chmod 755 "$STAGE/root/usr/local/bin/${CLI_NAME}"

# Sign the CLI binary directly. Hardened runtime is required if we plan
# to notarize.
if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp \
        --sign "$CODESIGN_IDENTITY" \
        "$STAGE/root/usr/local/bin/${CLI_NAME}"
else
    codesign --force --sign - "$STAGE/root/usr/local/bin/${CLI_NAME}" 2>/dev/null || true
fi

# Build the component package.
pkgbuild \
    --root "$STAGE/root" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    "$STAGE/${CLI_NAME}-component.pkg"

# Wrap in a distribution package so the installer shows a proper title.
cat > "$STAGE/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>meowpass — MeowPassword CLI</title>
    <organization>io.river</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <choices-outline>
        <line choice="default">
            <line choice="${IDENTIFIER}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${IDENTIFIER}" visible="false">
        <pkg-ref id="${IDENTIFIER}"/>
    </choice>
    <pkg-ref id="${IDENTIFIER}" version="${VERSION}" onConclusion="none">${CLI_NAME}-component.pkg</pkg-ref>
</installer-gui-script>
XML

PRODUCTBUILD_ARGS=(
    --distribution "$STAGE/distribution.xml"
    --package-path "$STAGE"
)
if [[ -n "${CODESIGN_INSTALLER_IDENTITY:-}" ]]; then
    PRODUCTBUILD_ARGS+=(--sign "$CODESIGN_INSTALLER_IDENTITY" --timestamp)
fi
PRODUCTBUILD_ARGS+=("$PKG_NAME")

productbuild "${PRODUCTBUILD_ARGS[@]}"

echo
echo "Built $PKG_NAME"
echo "  size: $(du -h "$PKG_NAME" | cut -f1)"
if [[ -n "${CODESIGN_INSTALLER_IDENTITY:-}" ]]; then
    pkgutil --check-signature "$PKG_NAME" | head -6
fi
