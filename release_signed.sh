#!/usr/bin/env bash
# release_signed.sh — the local "Developer ID" build scheme.
#
# Produces a signed, notarized, stapled *universal* MeowPassword.app and DMG
# for direct distribution outside the Mac App Store — the same output the CI
# (.github/workflows/build-app.yml) makes on a tag, but runnable locally so you
# can produce and test a real Developer ID build without pushing.
#
# ── One-time prerequisites ────────────────────────────────────────────────
#   1. A **Developer ID Application** certificate in your login keychain.
#      You currently have "Apple Distribution" (App Store) and "Apple
#      Development" — but NOT Developer ID, which is what notarized DMGs need.
#      Create it once:
#        https://developer.apple.com/account/resources/certificates  →  +  →
#        "Developer ID Application"  →  download  →  double-click to install.
#      (Optionally also "Developer ID Installer" if you sign the CLI .pkg.)
#
#   2. A notarytool credential profile stored in your keychain:
#        xcrun notarytool store-credentials meowpass-notary \
#          --apple-id "you@example.com" --team-id U3Z59VXPUB \
#          --password <app-specific-password>
#      App-specific password: https://appleid.apple.com → Sign-In & Security.
#
# ── Usage ─────────────────────────────────────────────────────────────────
#   ./release_signed.sh                       # auto-detect identity + profile
#   CODESIGN_IDENTITY="Developer ID Application: …" ./release_signed.sh
#   NOTARY_PROFILE=meowpass-notary ./release_signed.sh
#   APPLE_ID=you@x.com APP_PW=abcd-efgh-ijkl-mnop ./release_signed.sh
#   SKIP_NOTARIZE=1 ./release_signed.sh       # sign only (no notarization)

set -euo pipefail

APP_NAME="MeowPassword"
APP_DIR="${APP_NAME}.app"
TEAM_ID="${APPLE_TEAM_ID:-U3Z59VXPUB}"
NOTARY_PROFILE="${NOTARY_PROFILE:-meowpass-notary}"

# ── 1. Resolve the Developer ID Application identity ───────────────────────
if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
    CODESIGN_IDENTITY="$(security find-identity -v -p codesigning \
        | grep "Developer ID Application" | head -1 \
        | sed -E 's/.*"([^"]+)".*/\1/' || true)"
fi
if [[ -z "$CODESIGN_IDENTITY" ]]; then
    cat >&2 <<'MSG'
ERROR: No "Developer ID Application" certificate found in your keychain.

You have Apple Distribution (App Store) and Apple Development, but a
directly-distributed / notarized DMG needs a *Developer ID Application*
certificate. Create it once at:

  https://developer.apple.com/account/resources/certificates  →  +  →
  "Developer ID Application"

then download and double-click the .cer to install it, and re-run this script.
(Or export it and set CODESIGN_IDENTITY explicitly.)
MSG
    exit 1
fi
echo "▸ Signing identity: $CODESIGN_IDENTITY"

# ── 2. Decide notarization mode ────────────────────────────────────────────
NOTARIZE=1
if [[ "${SKIP_NOTARIZE:-0}" == "1" ]]; then
    NOTARIZE=0
    echo "▸ SKIP_NOTARIZE=1 — will sign but not notarize."
elif [[ -n "${APPLE_ID:-}" && -n "${APP_PW:-}" ]]; then
    echo "▸ Notarizing with Apple ID credentials from the environment."
elif xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "▸ Notarizing with keychain profile: $NOTARY_PROFILE"
else
    NOTARIZE=0
    echo "▸ No notary credentials (env APPLE_ID/APP_PW or profile '$NOTARY_PROFILE')."
    echo "  Producing a SIGNED but UN-NOTARIZED build. See the header for setup."
fi

notarize() {  # $1 = path to .zip/.dmg/.pkg
    local target="$1"
    if [[ -n "${APPLE_ID:-}" && -n "${APP_PW:-}" ]]; then
        xcrun notarytool submit "$target" --wait \
            --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PW"
    else
        xcrun notarytool submit "$target" --wait --keychain-profile "$NOTARY_PROFILE"
    fi
}

# ── 3. Build + sign the universal app ──────────────────────────────────────
# build_app.sh applies the hardened runtime + entitlements + timestamp when
# CODESIGN_IDENTITY is set, and builds universal (arm64 + x86_64) by default.
CODESIGN_IDENTITY="$CODESIGN_IDENTITY" SKIP_DMG=1 ./build_app.sh
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_DIR/Contents/Info.plist")"

# ── 4. Notarize + staple the .app ──────────────────────────────────────────
if [[ "$NOTARIZE" == "1" ]]; then
    echo "▸ Notarizing $APP_DIR (this can take a few minutes)…"
    ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" notary-app.zip
    notarize notary-app.zip
    xcrun stapler staple "$APP_DIR"
    rm -f notary-app.zip
fi

# ── 5. Build + notarize + staple the DMG ───────────────────────────────────
VERSION="$VERSION" ./make_dmg.sh
DMG="${APP_NAME}-${VERSION}.dmg"
if [[ "$NOTARIZE" == "1" ]]; then
    echo "▸ Notarizing $DMG…"
    notarize "$DMG"
    xcrun stapler staple "$DMG"
    echo "▸ Gatekeeper assessment:"
    spctl -a -vv -t open --context context:primary-signature "$DMG" || true
fi

echo
echo "✅ Done: $DMG"
if [[ "$NOTARIZE" != "1" ]]; then
    echo "   (signed but not notarized — users will still see a Gatekeeper prompt)"
fi
