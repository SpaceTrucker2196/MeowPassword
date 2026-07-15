# In-app purchases — theme packs

Setup and testing checklist for the three theme-pack IAPs. Design/billing
contract: [`themes/README.md`](themes/README.md). App Store record basics:
[`APPSTORE.md`](APPSTORE.md).

## The products

One **non-consumable** per pack, on the `io.river.MeowPassword` record
(multiplatform — iOS and macOS share the purchases via universal purchase).

| Reference name | Product ID | Price |
|---|---|---|
| Spy Thriller Theme Pack | `io.river.meowPassword.spyThemePack` | $1.99 (Tier 2) |
| Kremlin Cartoon Theme Pack | `io.river.meowPassword.kremlinThemePack` | $1.99 (Tier 2) |
| Pyongyang Poster Theme Pack | `io.river.meowPassword.pyongyangThemePack` | $1.99 (Tier 2) |

The camelCase product IDs are a **cross-platform SKU contract** with the
Android build (Play Billing must use byte-identical IDs). They intentionally
differ in casing from the bundle id — do not "normalize" them, ever.
`Theme.ID.productID` in `Sources/MeowUI/Theme.swift` and
`Configuration.storekit` must stay byte-identical to this table
(`Tests/MeowUITests/ThemeTests.swift` locks the code side).

## App Store Connect setup (one-time)

> **Status 2026-07-15: DONE via the ASC API** (steps 2–5). All three
> products exist in state READY_TO_SUBMIT with localized metadata (en-US,
> en-GB, de-DE, fr-FR, ja), $1.99 USA-base price schedule, availability in
> all 175 territories (+ future), review notes, and a Theme Studio review
> screenshot attached. ASC IAP ids: spy 6791235721, kremlin 6791235847,
> pyongyang 6791235917. Remaining: steps 1 and 6 below.

1. **Paid Apps agreement.** Business → Agreements, Tax, and Banking → the
   *Paid Apps* agreement must be Active (banking + tax forms complete).
   Without it, purchases fail in sandbox AND review rejects the build.
   (Record creation worked regardless — verify this before submitting.)
2. ~~**Create the IAPs.**~~ Done — type **Non-Consumable**, reference name
   and product ID exactly per the table.
3. ~~**Pricing.**~~ Done — $1.99 base (US), ASC-derived worldwide prices,
   available in all territories including future ones.
4. ~~**Localized metadata**~~ Done for en-US, de-DE, fr-FR, ja, en-GB,
   matching the in-app `Localizable.xcstrings` names.
5. ~~**Review screenshot**~~ Done — Theme Studio simulator screenshot on
   each IAP, review note: "Cosmetic theme pack - restyles the app's colors
   and decorations app-wide. No feature changes."
6. **Attach to a version.** First-time IAPs go to review **with an app
   version**: on the version page, in the In-App Purchases section, add all
   three before submitting the build. (After the first approval, IAP metadata
   edits can be reviewed standalone.)

## Code / repo facts (already wired)

- StoreKit 2 storefront: `Sources/MeowThemeStore/ThemeStore.swift` — loads
  products, purchases with verification, `Transaction.updates` listener,
  `AppStore.sync()` restore, entitlement rebuild at launch.
- Ownership + selection persist in the App Group
  (`group.io.river.MeowPassword`) so the iMessage/Share extensions render
  purchased themes without linking StoreKit.
- Store UI: `ThemeStudioView` — iOS palette button → sheet; macOS Settings
  (Cmd+,). Restore Purchases is in the footer (App Review requires it).
- Local testing storefront: `Configuration.storekit` (repo root), wired into
  both schemes' run actions by XcodeGen.
- fastlane `release` lanes keep `precheck_include_in_app_purchases: false` —
  precheck can't inspect IAPs when authenticating with an ASC API key.
  Review IAP metadata manually in ASC instead.
- Non-App-Store macOS builds (Developer ID DMG via `build_app.sh`) have no
  receipt context: product loading fails and the Theme Studio shows packs
  locked with a retry — free themes are unaffected. This is by design.

## Testing

**Local (no ASC):** run from the **Xcode IDE** (Cmd+R) so the scheme's
StoreKit configuration is applied; buy each pack in the Theme Studio, then
use Debug → StoreKit → Manage Transactions to refund and watch the app fall
back to Shōwa. Known limitation: CLI `xcodebuild test` on current iOS 26.x
simulators does not sync the StoreKit configuration, so
`iOSAppTests/ThemeStoreTests.swift` skips there (it asserts fully under
Cmd+U in the IDE). `simctl launch` likewise doesn't apply the configuration.

**Sandbox (device, before release):**
1. Sandbox Apple Account (ASC → Users and Access → Sandbox Testers), signed
   in under Settings → Developer → Sandbox Apple Account.
2. Buy each pack ($1.99 shows in sandbox); verify the theme applies and the
   iMessage + Share extensions pick it up on next open.
3. Delete + reinstall → Restore Purchases recovers all three.
4. Interrupted purchase (Settings → Developer → sandbox interrupted
   purchases) → purchase completes via `Transaction.updates` on next launch.
5. Ask-to-buy (sandbox family approval) → Theme Studio shows the pending
   note; approve; pack unlocks without relaunching.
6. Refund via sandbox → app falls back to Shōwa; repurchase restores the
   original selection automatically.
7. macOS App Store build (TestFlight): buy on iOS, then Restore on macOS —
   universal purchase must grant the same packs.
