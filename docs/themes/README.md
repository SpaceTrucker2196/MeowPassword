# MeowPassword theme system

MeowPassword ships one **default** look and sells optional **theme packs** as
in-app purchases. Every theme is a *cosmetic reskin* — same app, same features,
different broadcast. Nothing about generation, analysis, or the MeowGram wire
format changes; only presentation tokens do.

| Theme | Doc | Status | Distribution |
|---|---|---|---|
| **Shōwa Broadcast** | [`../DESIGN.md`](../DESIGN.md) | **default** | Free — always installed |
| Spy Thriller ("00-Cat") | [`spy-thriller.md`](spy-thriller.md) | roadmap | In-app purchase |
| Kremlin Cartoon (Russian parody) | [`kremlin.md`](kremlin.md) | roadmap | In-app purchase |
| Pyongyang Poster (parody) | [`pyongyang.md`](pyongyang.md) | roadmap | In-app purchase |

The parody packs are **affectionate, comedic send-ups of poster/broadcast art
styles** — cosmetic only, never political commentary. Keep them light.

## How a theme is built — the token contract

Shōwa Broadcast (`DESIGN.md`) is the reference implementation. It centralizes
styling in one place per platform:

- **iOS/macOS:** the `GameShow` tokens in `Sources/MeowUI/MeowUI.swift`.
- **Android:** `app/src/main/kotlin/io/river/meowpassword/theme/GameShow.kt`.

A theme = a swap of those tokens, applied app-wide (never per-view). Each theme
doc fills in these **semantic roles** so the two platforms stay in parity:

| Role | Shōwa example | What it drives |
|---|---|---|
| **Floor** (dominant, ~60%) | Paper Cream | backgrounds, panel fills, negative space |
| **Command** (the shout) | Tomato Red | headline plates, primary CTA, the seal |
| **Celebrate** | Mustard Yellow | bursts, highlights, secondary accents |
| **Cool** (exactly one) | Teal | the single cool accent per composition |
| **Bind** | warm Ink | all outlines, text, hard offset shadows |
| **Seal** | Hanko Red | the circular approval stamp |

Plus four **decoration tokens** each theme defines:

- **Background motif** — Shōwa: flat cream + sunburst + halftone. (No digital gradients.)
- **Frame treatment** — Shōwa: thick ink border + hard blur-0 offset shadow, tilt 1–2°.
- **Signature stamp** — Shōwa: the hanko (認証成功 / "MEOW VERIFIED"), tilt ~8°.
- **Chyron script** — Shōwa: vertical katakana. Each theme names its own secondary script/voice.

## Shared laws (inherited by every theme)

These survive every reskin — they're the house craft, not the costume:

1. **Print discipline over digital polish.** Flat fields, screens, grain. No soft glows or glassmorphism. (Individual themes may allow their own era-appropriate finish, but default to flat.)
2. **Pin everything.** Nothing floats — framed, stamped, or pinned with a hard shadow.
3. **One shout, one whisper, a few stamps.** Sparse, hierarchical text.
4. **Rotation is the pulse.** Panels a little, stamps more; baselines stay true.
5. **Two scripts, equal billing.** A Latin voice + the theme's chyron script.
6. **A signature seal.** Every theme has its own "producer's approval" stamp.
7. **Master-level finish.** Kerned, aligned, color-matched.

## Billing & parity

- Base app + Shōwa are free. Each pack is a **one-time IAP**, StoreKit (iOS) +
  Play Billing (Android).
- **SKU parity:** identical camelCase product IDs across platforms, e.g.
  `io.river.meowPassword.spyThemePack`, `.kremlinThemePack`, `.pyongyangThemePack`
  (or bundle them as `.spyThemePacks`). Do not "normalize" the casing.
- Theme token sets must be **defined identically on both platforms** and land in
  the same release, exactly like the cross-platform stego contract.
- A restore-purchases path is required on both stores.
