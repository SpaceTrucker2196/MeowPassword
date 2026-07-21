# App Store Connect — MeowPassword (iOS + macOS, one record)

MeowPassword ships as **one multiplatform App Store Connect record** — iOS
(iPhone + iPad) and macOS under the same bundle id **`io.river.MeowPassword`**.
All of it is driven by fastlane over the XcodeGen project; you supply an App
Store Connect API key and the lanes do the rest.

> The Developer ID (direct-download DMG) path — `build_app.sh` +
> `release_signed.sh` + `.github/workflows/build-app.yml` — is unchanged and
> independent. This document is only about the **App Store** path.

## Bundle IDs in the record

| Target | Bundle ID | Role |
|---|---|---|
| iOS + macOS app | `io.river.MeowPassword` | the app (both platforms) |
| iMessage extension | `io.river.MeowPassword.Messages` | MeowGram in the Messages drawer |
| Share extension | `io.river.MeowPassword.Share` | "Decode MeowGram" share sheet |

The two extension App IDs register automatically at first build via
`-allowProvisioningUpdates` (the lanes pass it), so there's nothing to create
by hand.

## One-time setup

1. **Create an App Store Connect API key** (App Store Connect → Users and
   Access → Integrations → App Store Connect API → **+**). Give it the *App
   Manager* role. Download the `AuthKey_XXXXXXXXXX.p8` (once only).

2. **Export the key to the shell** (locally or as CI secrets):
   ```bash
   export APP_STORE_CONNECT_API_KEY_KEY_ID=XXXXXXXXXX          # the 10-char key id
   export APP_STORE_CONNECT_API_KEY_ISSUER_ID=<issuer-uuid>    # top of the Integrations page
   export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH=~/Downloads/AuthKey_XXXXXXXXXX.p8
   # (CI: set APP_STORE_CONNECT_API_KEY_KEY to the .p8 contents/base64 instead of a path)
   ```
   The issuer defaults to the river.io account if unset; team id is inferred
   from the key.

3. **Create the app record once (web UI).** Apple does **not** allow creating
   an app record through the App Store Connect API (the `apps` resource is
   GET/UPDATE only), so this one step is manual:
   [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Apps → **+**
   → New App → tick **iOS** *and* **macOS**, Name **MeowPassword**, Bundle ID
   **`io.river.MeowPassword`** (already registered), SKU **meowpassword**.

   `fastlane setup` prints these exact values and confirms once the record
   exists — run it to check status:
   ```bash
   fastlane setup
   ```
   Everything after this (builds, TestFlight, metadata) is fully automated with
   the API key.

## Ship builds

TestFlight (internal testing):
```bash
fastlane ios beta          # build + upload the iOS app (with both extensions)
fastlane mac beta          # build + upload the macOS app (same record, osx platform)
```

App Store review (uploads the build + pins the version; does not auto-submit):
```bash
fastlane ios release
fastlane mac release
```

Both `release` lanes upload with `submit_for_review: false` so you do the final
"Submit for Review" in the ASC UI after checking metadata/screenshots.

## Signing & entitlements

- **Automatic signing** via `-allowProvisioningUpdates` + the API key — no
  manual profiles. Team `U3Z59VXPUB` (override with `DEVELOPMENT_TEAM`).
- **iOS**: sandboxed by default; declares `NSPhotoLibraryAddUsageDescription`.
- **macOS (App Store)**: the `MeowPasswordMac` Xcode target signs with
  `Sources/MeowPasswordApp/Resources/MeowPassword-AppStore.entitlements`
  (**App Sandbox** on). Note: under the MAS sandbox, "Install Command-Line
  Tool…" (writing to `/usr/local/bin`) and some Services behaviors are
  restricted — that's expected; direct-download builds keep those.

## Metadata & screenshots

`ios release` / `mac release` currently pass `skip_metadata: true` /
`skip_screenshots: true` (binary-only). To manage listing text and shots from
the repo, fill `fastlane/metadata/en-US/` (name, subtitle, description,
keywords, support/marketing URLs) and `fastlane/screenshots/`, then drop those
`skip_*` flags. `fastlane deliver init` can scaffold the metadata tree from an
existing app record.

## Versioning

`MARKETING_VERSION` lives in `project.yml` (currently `1.2.1`). Build numbers
(`CURRENT_PROJECT_VERSION`) are set to the git commit count by
`ci_scripts/ci_post_clone.sh`, which **patches the value into `project.yml`
before `xcodegen generate`** (an exported env var doesn't reach `xcodebuild
archive` — see below). Bump `MARKETING_VERSION` in `project.yml` for each new
App Store version.

## First-run checklist

- [ ] API key created + env vars exported
- [ ] `fastlane setup` (record exists for iOS + macOS)
- [ ] `fastlane ios beta` succeeds → build appears in TestFlight
- [ ] `fastlane mac beta` succeeds → macOS platform added under the same record
- [ ] Fill App Store listing (privacy, category = Utilities, screenshots)
- [ ] Theme-pack IAPs created + attached to the version — see [`IAP.md`](IAP.md)
- [ ] `fastlane ios release` / `fastlane mac release` → Submit for Review in ASC

## In-app purchases

Theme packs are one-time non-consumable IAPs. Setup, product IDs, review
screenshots, and the sandbox test matrix live in [`IAP.md`](IAP.md).

## Release-pipeline fixes (2026-07-21)

Two things had been making Xcode Cloud builds go "missing" in App Store Connect —
they uploaded but never became available for TestFlight. Both are now fixed:

1. **Build number was frozen at `1`.** `project.yml` pins
   `CURRENT_PROJECT_VERSION: "1"`, and `ci_scripts/ci_post_clone.sh` only
   `export`ed the bumped value — which (a) happened *after* `xcodegen generate`
   baked in `"1"`, and (b) didn't survive into the separate shell Xcode Cloud
   uses for `xcodebuild archive`. So every archive uploaded as `1.2.1 (1)`; ASC
   kept the first and silently rejected the rest as duplicates. **Fixed:**
   `ci_post_clone.sh` now `sed`-patches `CURRENT_PROJECT_VERSION` (= git commit
   count) into `project.yml` *before* generate. App + both extensions all read
   `$(CURRENT_PROJECT_VERSION)`, so they stay in sync.
2. **Missing export-compliance key.** No `ITSAppUsesNonExemptEncryption` in any
   plist, but the app does real crypto (ChaCha20-Poly1305 in
   `MeowGramKit/MeowGram.swift`), so every build sat in "Missing Compliance"
   until manually cleared. **Fixed:** added `ITSAppUsesNonExemptEncryption =
   false` to both the iOS (`iOSApp/Info.plist`) and macOS
   (`Sources/MeowPasswordApp/Resources/Info.plist`) app plists, on the basis that
   the app uses only standard Apple-framework encryption for the user's own local
   data (EAR 740.17(b)(1) exemption). **This is an export-classification
   assertion — the owner should confirm it before the next submission.**

Separately, shipping the iMessage extension puts the app in the **iMessage App
Store**, which requires its *own* screenshot set — a submission/metadata gap,
not a build-availability one, and still open.

## Cross-platform note

The Android sibling (`~/projects/meowpassword-android`) now ships the same
five-theme system with the three paid packs as Play Billing IAPs whose product
IDs are byte-identical to the App Store SKUs (the parity rule in
[`IAP.md`](IAP.md)). Keep theme palettes and SKU strings in lockstep across the
two repos.
