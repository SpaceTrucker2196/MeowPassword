# Spy Thriller — "00-Cat" theme (IAP)

> A mid-century secret-agent title sequence, purring. Tuxedo black, a martini,
> a gun-barrel iris, and a cat with a licence to unlock.

An affectionate parody of the 1960s spy-film title designer's craft (Maurice
Binder / Saul Bass energy) — cosmetic only. Read [`README.md`](README.md) for the
token contract this fills in.

---

## Philosophy

Where Shōwa Broadcast is a loud studio, Spy Thriller is a *cold open*: a lone
silhouette, a spinning gun-barrel iris, a name typed onto a dossier. The mood is
sleek, nocturnal, and impossibly composed. Everything is high-contrast and
geometric — hard diagonals, target reticles, redacted bars — set on the deep
black of a tuxedo with a single stroke of gold like a cufflink catching light.
The cat is Agent 00-Cat: unbothered, immaculate, holding a key instead of a
Walther.

Restraint is the whole point. Shōwa shouts; this one *whispers a threat*. Two
colors do almost all the work — black and gold — with one clean off-white
"dossier paper" for reading, and a single drop of blood-red for the moment of
danger. Type is elegant and clinical: a crisp grotesque headline, a monospace
"CLASSIFIED" stamp, a filename in the corner. Motion, if any, is a slow iris and
a crosshair drifting to lock.

Cool, sparse, lethal. A game show would be undignified.

---

## Principles

1. **Cold-open restraint.** Two colors carry it (black + gold). Add a third only for danger.
2. **Geometry as tension.** Hard diagonals, reticles, iris circles, redaction bars.
3. **Dossier discipline.** Off-white paper for anything you actually read; the rest is night.
4. **One elegant shout, one clinical whisper.** A grotesque headline; a monospace stamp.
5. **The gun-barrel is the signature.** A white-ringed iris is this theme's seal.
6. **Rotation is subtle.** Cards barely tilt; the reticle does the leaning.

---

## Color — the quota

Ink-on-night, not pixels. Gold is rationed like real gilt.

| Role | Name | Hex | Usage |
|---|---|---|---|
| **Floor** (dominant) | Tuxedo Black | `#0E0E10` | Backgrounds, panels. The night. ~60%. |
| **Command** | Champagne Gold | `#C8A24C` | The shout — headline rules, primary CTA, the barrel ring. Gilt, not neon. |
| **Celebrate** | Dossier Paper | `#EDE7D6` | Readable surfaces — cards holding text, filenames, the score readout. |
| **Cool** (single accent) | Steel Blue | `#4A6A82` | Exactly one cool note — meters, secondary lines. |
| **Bind** | Onyx | `#050506` | Outlines, hairlines, hard shadows. Near-black on black = embossed edges. |
| **Danger** | Blood Red | `#B0201C` | The one drop of red: alerts, the "wrong passphrase," the crosshair lock. Rare. |
| **Seal** | Gun-Barrel White | `#F4F1EA` | The white iris ring of the signature stamp. |

**Rules** — roughly black 60 · gold 15 · dossier 15 · steel 5 · red ≤2 · onyx binds.
Gold is a *thin* stroke or small fill, never a flood. No glow; gold reads as
reflected light via a hard highlight edge, not a blur.

---

## Type

- **The Shout** — a tight, confident grotesque (Helvetica/Univers energy),
  ALL-CAPS, letter-spaced. Cold and clean. One per screen.
- **The Chyron** — a **dossier filename / classification** set in monospace,
  laid horizontally along a hairline: `FILE 00-CAT · EYES ONLY · スコア 7.48`.
  (Keep a katakana whisper as a nod to the house — spies work everywhere.)
- **The Whisper** — coordinates, timestamps, redaction: `LAT 51.5 · 23:07 · ████`.
- Latin grotesque + a monospace clinical voice are the two equal scripts here.

---

## Materials & motifs

- **Gun-barrel iris.** A set of concentric white/onyx rings — the signature seal.
  Put "00-CAT · MEOW LICENCE" inside; drift a crosshair to lock over the hero.
- **Redaction bars.** Solid onyx bars over "classified" text; reveal on tap.
- **Dossier cards.** Off-white paper cards with a thin gold rule and a
  paper-clip/stamp corner; a filename tab.
- **Diagonal light.** A single hard gold diagonal (the cufflink glint) crossing a panel.
- **Hard emboss, not glow.** Onyx-on-black edges + a hard offset shadow. No bloom.
- **Silhouettes.** The 00-Cat silhouette in gold, walking into the iris.

---

## Layout, rotation & rhythm

- **Cold-open framing:** deep black stage, one gold headline, the iris off-center,
  a dossier card of readable content, generous black air.
- **Rotation:** cards tilt ≤1°, the reticle/iris tilts ~6°; baselines stay true.
- **Repetition:** stacked classification stamps, a column of coordinates, a fan of hairlines.

## Do / Don't

**Do** — start from black; ration gold as thin gilt; keep readable text on dossier
paper; one grotesque shout; the iris is the seal; one drop of red for danger.
**Don't** — glow, gradient, or gloss the gold; add a second bright color; crowd the
night; use pure `#000` (use Onyx/Tuxedo); make it loud — that's Shōwa's job.

## Token mapping

| Contract role | Value |
|---|---|
| Floor | Tuxedo Black `#0E0E10` |
| Command | Champagne Gold `#C8A24C` |
| Celebrate | Dossier Paper `#EDE7D6` |
| Cool | Steel Blue `#4A6A82` |
| Bind | Onyx `#050506` |
| Seal | Gun-barrel iris (white/onyx rings), "00-CAT · MEOW LICENCE" |
| Background motif | Flat black + faint diagonal gold glint + a fine reticle grid at low opacity |
| Frame treatment | Onyx hairline border + hard shadow; dossier cards get a thin gold rule |
| Signature stamp | The gun-barrel iris + crosshair (replaces the hanko) |
| Chyron script | Monospace dossier filename; keep a katakana whisper |
