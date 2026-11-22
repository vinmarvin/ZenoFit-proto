# M09 — Elbow Flexion & Wrist Pour ("Tea Ceremony Pour")

> [!IMPORTANT]
> **v0.4 Zen Dojo Arcade Revision (`godot/mechanics/m09_tea_ceremony_pour/m09_mechanic.gd` — FIX PARTIAL):**
> - **Zen Dojo Theme:** Reaching for a ceramic *kyusu* teapot (`0.85 * L_arm`), curling it toward the shoulder with weighty visual drag (`τ = 0.20 s`), then pouring into a moving *yunomi* teacup via wrist roll (`>= 60°` for `1.0 s`). Update UI title to `"M09: Tea Ceremony Pour (Curl & Wrist Pour)"`.
> - **Anti-Cheat Fix (`AT-34`, `GP-ANTI-CHEAT-01`):** (1) Pour progress MUST check BOTH `absf(wrist_roll) >= 60°` **AND** horizontal alignment over the moving cup (`|hand.x - cup.x| <= 0.14 m`). (2) Fix `pick_hand_for_spawn(0)` to alternate hands in `BOTH_HANDS` mode.
> - **Hybrid Input & Juice:** Read `wrist_roll` from `XRHandTracker` wrist/palm roll OR `XRController3D.rotation.z`. Play warm tea-pouring water SFX during pour. *(Attach a lightweight teapot prop to Zeno's arm tip during intro demo so wrist rotation is visible without Zeno having fingers.)*

> Part of the spec pack (Godot 4.7 · PICO 4 Ultra & Meta Quest). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.9 Elbow Flexion and Wrist Pour — "Tea Ceremony Pour"

| Item | Spec |
|---|---|
| Real movement | Biceps-curl motion, then a wrist roll to pour |
| Body area / group | Elbows, forearms, wrists · **Chest/arms** |
| Safety level | A (arms only) |
| Priority | P1 |
| Calibration | Base calibration only (`L_arm`) |
| Feeling | Calculated and weighty |
| Source | **[D]** concept (visual drag); wrist pour added by me to cover the survey wrist/RSI need **[P]** |

### 6.9.1 Gameplay

- Pick up an ingredient from the shelf, curl it toward the shoulder (the ingredient lags behind the hand for a "heavy" feel), then hold it above the moving cauldron and **roll the wrist** to pour.
- The draft's "toss" is replaced by "pour" (safer for wrists, easier to measure). A toss mode may be added later **[P]**.

### 6.9.2 Geometry and formulas

```
d_ext    = 0.85 × L_arm            // hand-to-shoulder distance when reaching for the ingredient
d_curl   = 0.35 × L_arm            // curl complete when hand-to-shoulder ≤ d_curl
pour     : wrist roll ≥ 60° (about the forearm axis) while above the cauldron; 1.0 s of pour fills the vial
visual drag: p_obj += (p_hand − p_obj) × (1 − exp(−Δt / τ)),  τ = 0.20 s (heavy: 0.30 s)
steady lag  = v_hand × τ
cauldron    : x moves ±0.15 m at 0.2 m/s, at z = 0.30 m, chest height
```

**Simple problem (drag).** At 72 Hz `Δt = 0.0139 s`, `τ = 0.20 s`: each frame the object closes `1 − exp(−0.0139 / 0.20) = 6.7 %` of the gap. At hand speed `0.5 m/s` the steady lag is `0.5 × 0.20 = 0.10 m` (10 cm behind the hand).

**Case study (Rani).** `L_arm = 0.52 m` → `d_curl = 0.35 × 0.52 = 0.182 m`, `d_ext = 0.85 × 0.52 = 0.442 m`. She reaches 0.44 m to grab and curls to 0.18 m, a range matched to her arm, not a fixed 0.60 m assumption.

### 6.9.3 Scoring hooks

- Each completed curl = hit (`13` §7.1). Each full pour into the cauldron: `+50` **[P]**.

### 6.9.4 Safety and comfort

- Wrist roll comfortable limit 60°–80°; no forceful gripping, no flicks. Neutral wrist when curling.
- The weight is visual only; no extra resistance, no strength claims.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| `d_curl` factor | 0.35 × `L_arm` **[P]** | |
| `d_ext` factor | 0.85 × `L_arm` **[P]** | |
| Pour angle | 60° **[P]** | |
| Drag `τ` | 0.20 s (heavy 0.30 s) **[P]** | |
| Cauldron speed | 0.2 m/s **[P]** | |
| Pour fill time | 1.0 s **[P]** | |

## Open questions

1. Keep the toss as an advanced mode, or drop it?
2. Should different ingredients have different weights (different `τ`)?
3. Is wrist-only (no curl) a separate easy variant for the RSI need?
