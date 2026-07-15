# Shōwa Broadcast — MeowPassword design language

> The visual language of the golden-age Japanese variety hour, rebuilt with the
> discipline of a master print shop. Every canvas is a television moment.

This is the north-star aesthetic for **all** MeowPassword design and UI work —
the macOS app, the iOS/iPadOS app, the iMessage extension, marketing, and the
App Store assets. Read it before choosing a color, drawing a panel, or laying
out a screen. The shared SwiftUI implementation lives in `Sources/MeowUI/`;
this document is its rationale and its rulebook.

---

## Philosophy

Shōwa Broadcast treats every canvas as a television moment: a contestant is
revealed, a klaxon sounds, confetti hangs in the air. The energy is loud but
never sloppy — every ray of the sunburst is measured, every sticker is rotated
with intent, every border is a deliberate weight of ink. The work must read as
if a veteran broadcast-graphics artist labored over it frame by frame, cel by
cel, with painstaking attention.

Space is organized like a game-show set. A warm paper cream is the studio
floor; tomato red and mustard yellow are the stage lights; a deep ink outlines
everything the camera should see. Sunburst rays radiate from the point of
maximum drama. Halftone dot fields stand in for the roar of a studio audience —
texture that fills space without cluttering it. Panels sit inside thick borders
with hard, unblurred shadows, like title cards physically stacked in front of
the lens. Nothing floats vaguely; everything is pinned, stamped, framed.

Type performs. A single enormous headline — chunky, rounded, almost inflatable —
does the shouting, while katakana runs vertically down the margins like a
broadcast chyron, and tiny clinical labels (episode numbers, prize amounts,
contestant IDs) whisper systematic order underneath the noise. Latin and
Japanese scripts share the stage as equals. Text is sparse: one shout, one
whisper, a few stamps. The hanko — a red circular seal — is the signature
gesture, the producer's approval pressed onto every frame.

Color obeys a strict quota: cream dominates, red commands, yellow celebrates, a
single teal or cobalt accent cools the composition, ink binds it. No gradients
that feel digital; only flat fields, dot screens, and paper-grain warmth. The
palette must feel printed, slightly sun-faded, pulled from a 1974 broadcast
archive and lovingly restored.

Rhythm comes from repetition with variation: rows of dots, fans of rays, stacks
of badges — dense accumulations that reward a second look. Rotation is the
pulse; panels tilt one or two degrees, stickers tilt eight, but baselines
inside them stay true. Balance is asymmetric yet resolved, the way a great TV
director frames a shot: weight on one side, a counterweight of texture on the
other, generous breathing room so the shout can land.

Joyful, absurd, and immaculate: a game show broadcast by perfectionists.

---

## Principles (the short version)

1. **Broadcast moment, print discipline.** Loud energy, zero sloppiness. If it
   looks quick, it's wrong.
2. **Pin everything.** Nothing floats. Everything is framed, stamped, or pinned
   with a hard shadow.
3. **Flat and printed, never digital.** Solid fields, halftone dots, paper
   grain. No soft/blurry gradients, no glassy glows.
4. **One shout, one whisper, a few stamps.** Text is sparse and hierarchical.
5. **Rotation is the pulse.** Panels 1–2°, stickers ~8° — baselines inside stay
   true.
6. **Two scripts, equal billing.** Latin headline + katakana chyron.
7. **The hanko is the signature.** A red seal is the producer's approval.
8. **Master-level finish.** Kerned, aligned, color-matched — looks like it took
   countless hours.

---

## Color — the strict quota

Cream dominates the field; the others are rationed. Think of it as ink on warm
paper, not pixels on a screen.

| Role | Name | Hex | Usage |
|---|---|---|---|
| **Studio floor** (dominant) | Paper Cream | `#F4E9CE` | Backgrounds, panel fills, negative space. The most common color on screen. |
| **Commands** | Tomato Red | `#E23B2E` | The primary shout — headline plates, the lead CTA, the hanko. Used decisively, never as filler. |
| **Celebrates** | Mustard Yellow | `#F2B417` | Sunbursts, prize/celebration accents, secondary highlights. |
| **Cools** (single accent) | Teal | `#1B8A8A` | Exactly one cool accent per composition. Cobalt `#1B4B9B` is the alternate — pick one, not both. |
| **Binds** | Ink | `#1A1712` | All outlines, text, hard shadows. A warm near-black, not pure `#000`. |
| Texture | Halftone Ink | `#1A1712` @ 12–18% | Dot fields for "studio audience" texture. |
| Seal | Hanko Red | `#C1272D` | The circular approval seal only. Slightly deeper than Tomato. |

**Rules**
- Roughly **cream 60% · ink 20% · red 10% · yellow 8% · teal 2%** by area. When
  in doubt, add cream and subtract everything else.
- **No digital gradients.** Flat fields and halftone screens only. A faint
  paper-grain texture is welcome; a smooth screen-blend is not.
- Slightly **sun-faded** — nudge saturation down a touch so nothing feels neon.

> **Note on the current build:** implemented. The static `GameShow` enum is
> gone; styling flows through the semantic `Theme` tokens in
> `Sources/MeowUI/Theme.swift` (Floor/Command/Celebrate/Cool/Bind/Seal +
> support roles), read via `@Environment(\.theme)`. Shōwa Broadcast is the
> shipping default (`ThemeDefinitions.swift`), with the flat cream field +
> sunburst + halftone as its `ThemedBackground` motif. The original neon look
> survives byte-exactly as the free "GameShow Classic" theme. The hanko seal
> art remains to add.

---

## Type

- **The Shout** — one enormous headline per screen. Chunky, rounded, almost
  inflatable (heavy rounded weight). It carries the drama; everything else
  supports it.
- **The Chyron** — katakana set vertically down a margin, like a broadcast
  ticker. Decorative but real Japanese, never gibberish.
- **The Whisper** — tiny clinical labels: episode numbers, IDs, byte counts,
  scores, "EP. 04 / スコア 7.48". Monospaced or condensed, uppercase, systematic.
  They imply a rigorous production behind the noise.
- Latin and Japanese are **equal citizens** — pair them, don't subordinate one.
- **Sparse:** one shout, one whisper, a few stamps. If a screen has three
  headlines, it has none.

---

## Materials & motifs

- **Thick ink borders + hard offset shadow.** Every panel is a title card:
  `~3–4pt` ink stroke, a solid (blur-radius 0) shadow offset `~4pt x / 5pt y`.
  Cards stack in front of the lens; they do not glow.
- **Sunburst rays.** Radiate from the point of maximum drama (the winner, the
  hero). Measured and even — a fan, not a scribble.
- **Halftone dot fields.** Ink dots at low opacity for audience-roar texture.
  Fill space; never obscure content.
- **Hanko.** A red circular seal, tilted ~8°, pressed onto the frame as the
  signature/approval gesture (e.g. "MEOW VERIFIED").
- **Badges & stamps.** Small rotated pills/seals accumulate in stacks — prize
  amounts, ranks, "認証成功".
- **Confetti / sparkles.** Suspended, sparse, celebratory. (The Core-Animation
  `SparkleField` is our motion take on this; keep it subtle.)

---

## Layout, rotation & rhythm

- **Organize like a set:** a clear stage (hero), stage lights (accents), a
  chyron margin, title cards stacked front-of-lens. Everything is pinned.
- **Rotation is the pulse:** panels tilt **1–2°**, stickers/hanko tilt **~8°**,
  but **type baselines inside a tilted panel stay horizontal and true.**
- **Asymmetric yet resolved:** weight on one side, a counterweight of texture
  (dots/rays) on the other. Leave generous breathing room so the shout lands.
- **Repetition with variation:** rows of dots, fans of rays, stacks of badges —
  dense accumulations that reward a second look.

---

## Do / Don't

**Do**
- Start from cream and ration every other color.
- Frame, stamp, and pin with hard shadows.
- Use halftone and paper grain for texture.
- Let one headline shout; keep everything else quiet.
- Pair Latin + katakana as equals.
- Tilt panels a little, stickers more; keep baselines true.

**Don't**
- Reach for smooth digital gradients, soft glows, or glassmorphism.
- Use pure black (`#000`) — use warm Ink.
- Add a second cool accent (one teal *or* cobalt, never both).
- Crowd the frame; the shout needs air.
- Fake the Japanese — use real katakana.
- Let anything float without a border, shadow, or stamp.

---

## Implementation map (`Sources/MeowUI/`)

| Motif | Component | Status |
|---|---|---|
| Title card (border + hard shadow) | `GamePanel` | ✅ matches (thick stroke, blur-0 offset shadow) |
| The shout / CTA | `NeonButton` | ✅ shape/shadow match; recolor to the quota |
| Chyron | katakana labels in views (`ルール`, `にゃんメール`, …) | ✅ present |
| Whisper labels | score/byte/`EP` captions | ✅ present |
| Confetti | `SparkleField` (Core Animation, 3D) | ✅ present — keep subtle |
| Palette | `Theme` tokens (`Theme.showa`) | ✅ cream/red/yellow/teal/ink quota shipped as default |
| Sunburst rays | `ThemedBackground` (.sunburstHalftone) | ✅ low-opacity wedge fan |
| Halftone dot field | `ThemedBackground` (.sunburstHalftone) | ✅ bottom "audience" dots at 12–18% ink |
| Hanko seal | — | ➕ to add (e.g. "MEOW VERIFIED" stamp; caption tokens exist as `Theme.sealCaption`) |

When evolving the look, change the **`Theme` definitions and shared components
once**, so every surface (both apps + the iMessage extension) moves together.
Never hand-tune colors per view.
