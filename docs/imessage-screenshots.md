# iMessage App Store screenshots

Bundling the `MeowGramMessages` extension gives MeowPass! a listing in the
**iMessage App Store** (the in-Messages app browser), which requires its **own**
screenshot set in App Store Connect — separate from the main iOS app
screenshots. This is the last metadata gap before the version can be submitted;
see [`APPSTORE.md`](APPSTORE.md).

## Where in App Store Connect

App Store Connect → the app version → scroll to the **Messages App** section
(appears because the build embeds an `.appex` of type
`com.apple.message-payload-provider`). Upload screenshots there per device size.
These are independent of the main app's screenshot wells.

## Sizes (reuse the current app captures)

iMessage screenshots use the **same device-size buckets** as regular App Store
screenshots, and the existing captures are already at current sizes, so no new
tooling is needed — reuse them:

| Device bucket | Pixels | Reuse from `fastlane/screenshots/en-US/` |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | `iphone-2-compose.png`, `iphone-3-decode.png` |
| iPad 13" | 2064 × 2752 | `ipad-2-compose.png`, `ipad-3-decode.png` |

Two shots per device is enough for the iMessage listing (Apple allows up to 10).
The compose + decode pair tells the whole MeowGram story: hide a message in a
cat, send it, reveal it. `iphone-1-generate.png` (the password screen) is *not*
part of the iMessage experience — leave it out of this set.

## Captions (optional overlay copy, localized)

If you frame the shots with caption text, keep it short and parallel across
locales. Matches the in-app `Localizable.xcstrings` register.

| Shot | en / en-GB | de | fr | ja |
|---|---|---|---|---|
| Compose | Hide a secret in a cat | Verstecke ein Geheimnis in einer Katze | Cachez un secret dans un chat | ネコに秘密を隠そう |
| Decode | Tap to reveal the meow | Tippen und die Nachricht zeigen | Touchez pour révéler le miaou | タップして解読 |

## Ideal vs. now

The reuse set shows the **standalone app** UI, which is a valid, submittable
first set. A more polished set would show the extension **inside a Messages
conversation** (the app drawer + a MeowGram bubble in a thread). That needs a
manual capture — the repo's screenshots are all hand-captured (no `snapshot`
automation), and the Messages app can't be driven headlessly:

1. Run the app on a device/simulator, open **Messages**, open the MeowGram app
   from the drawer, compose a MeowGram into a conversation.
2. Screenshot the drawer view and the sent-bubble view at the sizes above.
3. Drop them next to the existing captures and swap them into the table.

## Upload checklist

- [ ] Main app screenshots already uploaded (Generate / Compose / Decode) — done
- [ ] iMessage set: 2× iPhone 6.9" (compose, decode) uploaded to the Messages App section
- [ ] iMessage set: 2× iPad 13" (compose, decode) uploaded
- [ ] (Optional) localized caption overlays per the table
- [ ] Attach the three theme-pack IAPs to the version — see [`IAP.md`](IAP.md)
- [ ] Confirm `ITSAppUsesNonExemptEncryption` classification — see [`APPSTORE.md`](APPSTORE.md)
