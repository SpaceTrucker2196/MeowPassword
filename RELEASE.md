# Releasing MeowPassword

The GitHub Actions workflow (`.github/workflows/build-app.yml`) does the
whole loop on `macos-15`:

1. `swift build -c release` for the CLI and the SwiftUI app
2. `./build_app.sh` to assemble `MeowPassword.app`
3. Re-sign nested binaries with **Developer ID Application** (hardened
   runtime + timestamp) when signing secrets are configured
4. **Notarize** the `.app` with `notarytool` and staple the ticket
5. `./make_dmg.sh` to produce `MeowPassword-<version>.dmg`
6. Notarize + staple the `.dmg`
7. Upload both `MeowPassword-<version>.app.zip` and
   `MeowPassword-<version>.dmg` as workflow artifacts
8. On a `v*` tag: attach both to the GitHub Release

Team ID is baked in as `APPLE_TEAM_ID: U3Z59VXPUB` (same account as
StatusGalactic-iOS).

## One-time secret setup

Add these to the repo's **Settings → Secrets and variables → Actions**:

| Secret | Required for | How to get it |
|---|---|---|
| `APPLE_DEVELOPER_ID_CERT_P12_BASE64` | signing the `.app` and DMGs | Keychain Access → find **Developer ID Application: Jeffrey Kunzelman (U3Z59VXPUB)** → File → Export → `.p12` → `base64 -i cert.p12 \| pbcopy` |
| `APPLE_DEVELOPER_ID_CERT_PASSWORD` | signing the `.app` and DMGs | Password you set when exporting the `.p12` |
| `APPLE_DEVELOPER_ID_INSTALLER_CERT_P12_BASE64` | signing the `meowpass.pkg` | Keychain Access → **Developer ID Installer: Jeffrey Kunzelman (U3Z59VXPUB)** → export same way |
| `APPLE_DEVELOPER_ID_INSTALLER_CERT_PASSWORD` | signing the `meowpass.pkg` | Password for the installer `.p12` |
| `APPLE_NOTARY_APPLE_ID` | notarizing anything | Apple ID email for the developer account |
| `APPLE_NOTARY_APP_PASSWORD` | notarizing anything | App-specific password from [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords |

Without these secrets the workflow still runs — it just falls back to
ad-hoc signing (fine for local testing, not distributable). PR builds
never receive secrets, so they always produce ad-hoc artifacts.

> **Prerequisite the account still needs:** the signing above requires a
> **Developer ID Application** certificate (and, for the CLI `.pkg`, a
> **Developer ID Installer** cert). The team currently has *Apple
> Distribution* (App Store) and *Apple Development* only. Create the missing
> cert once at
> [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates)
> → **+** → *Developer ID Application*, install it, then export it for the
> secrets above (CI) and/or use it locally (below).

## Building a signed build locally (your Developer ID)

`./release_signed.sh` is the local counterpart to CI: it builds the universal
app, signs it with your **Developer ID Application** cert (hardened runtime +
timestamp), notarizes and staples the `.app` and the DMG, and prints a
Gatekeeper assessment — no tag push required.

```bash
# one-time: store notary credentials in the keychain
xcrun notarytool store-credentials meowpass-notary \
  --apple-id "jeff@river.io" --team-id U3Z59VXPUB --password <app-specific-pw>

./release_signed.sh                 # auto-detects the Developer ID cert + profile
SKIP_NOTARIZE=1 ./release_signed.sh # sign only (skip notarization)
```

It auto-detects the Developer ID Application identity (override with
`CODESIGN_IDENTITY=…`) and the `meowpass-notary` profile (override with
`NOTARY_PROFILE=…`, or pass `APPLE_ID`/`APP_PW` directly). If the cert or notary
credentials are missing it explains exactly what to create and, for missing
notary creds, still produces a signed-but-un-notarized build.

## Cutting a release

```bash
# bump the version in the app's Info.plist
plutil -replace CFBundleShortVersionString -string 1.1.0 \
  Sources/MeowPasswordApp/Resources/Info.plist

git commit -am "chore: bump to 1.1.0"
git tag v1.1.0
git push --follow-tags
```

CI will build, sign, notarize, and post the artifacts to a new GitHub
Release named after the tag.

## Release artifacts

Each tag build attaches to the GitHub Release:

- `MeowPassword-<version>.app.zip` — signed + notarized `.app` bundle
- `MeowPassword-<version>.dmg` — drag-to-Applications DMG containing the `.app`
- `meowpass-<version>.pkg` — Installer package that drops the CLI at `/usr/local/bin/meowpass`
- `meowpass-CLI-Installer-<version>.dmg` — same `.pkg` wrapped in a DMG so users can double-click a single file

## Installing the CLI from the app

The main window's **File → Install Command-Line Tool…** menu item finds the
bundled `meowpass` and offers to drop it at any user-chosen path via
`NSSavePanel`. If the destination requires admin rights (e.g. `/usr/local/bin`
on a fresh Mac), the app prompts via `osascript` for direct/notarized builds.
Under the Mac App Store sandbox, admin escalation is blocked — the user needs
to pick a directory they own (like `~/bin`) or use the standalone
`meowpass-<version>.pkg` installer.

## Mac App Store submission

The workflow above produces a Developer ID (direct-download) build. For MAS,
Xcode is currently required; the pieces that are already in place:

- `Sources/MeowPasswordApp/Resources/MeowPassword-AppStore.entitlements`
  turns on `com.apple.security.app-sandbox` on top of the base entitlements.
- `Info.plist` declares `LSApplicationCategoryType`, `NSPrincipalClass`,
  `NSHumanReadableCopyright`, `NSSupportsAutomaticTermination`, and the
  standard bundle metadata that App Review checks.
- The bundle ID is `io.river.MeowPassword`; register an app record with
  the same ID in App Store Connect before submitting.

Xcode steps (once per release):

1. Open the SwiftPM package in Xcode → select the `MeowPasswordApp` target.
2. Signing & Capabilities → Team: **U3Z59VXPUB**, provisioning:
   *Mac App Store*, entitlements: **MeowPassword-AppStore.entitlements**.
3. Product → Archive → *Distribute App* → *Mac App Store* → upload.
4. Fill out the App Store Connect metadata (screenshots, description,
   privacy policy) and submit for review.

## Verifying a signed build locally

```bash
codesign -dv --verbose=4 MeowPassword.app
spctl -a -vv -t execute MeowPassword.app             # should say "accepted: Notarized Developer ID"
spctl -a -vv -t open --context context:primary-signature MeowPassword-1.1.0.dmg
xcrun stapler validate MeowPassword.app
xcrun stapler validate MeowPassword-1.1.0.dmg
```
