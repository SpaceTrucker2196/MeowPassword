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

`MARKETING_VERSION` lives in `project.yml` (currently `1.1.0`). Build numbers
(`CURRENT_PROJECT_VERSION`) are set to the git commit count by
`ci_scripts/ci_post_clone.sh` (Xcode Cloud) — bump `MARKETING_VERSION` in
`project.yml` for each new App Store version.

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
