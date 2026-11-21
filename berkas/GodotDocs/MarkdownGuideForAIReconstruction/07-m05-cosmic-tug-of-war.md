# M05 — Seated Row ("Cosmic Tug-of-War")

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.5 Seated Row — "Cosmic Tug-of-War"

| Item | Spec |
|---|---|
| Real movement | Pull both hands from forward to the waist like rowing |
| Body area / group | Mid-back, rear shoulders · **Back/trunk** |
| Safety level | A (arms only) |
| Priority | P1 |
| Calibration | Base calibration only (`R_f` per hand) |
| Feeling | Heavy physical tension (simulated) |
| Source | **[P]**; real resistance needs equipment **[S]** |

### 6.5.1 Gameplay

- Space debris is tethered ahead. Grab the handle (hold grip), pull toward the waist to reel the debris in.
- **Pseudo-weight:** the debris moves less than the hand (`gain g < 1`), so it feels heavy. Visual drag and a low continuous rumble add to the effect.
- Pulls must complete within a stroke window. An incomplete pull lets the debris drift back (no penalty).

### 6.5.2 Geometry and formulas

```
z_start  = k × R_f,hand
z_end    = 0.15 m                          // near the waist/chest
S        = z_start − z_end                 // stroke length
progress per stroke = g × S
g        = min(1, D / (N × S))             // per-hand gain so every user needs about N strokes
D = 1.0 m of debris to reel in,  N = 7 strokes target [P];  stroke window T_s = 2.0 s [P]
```

**Simple problem.** `R_f = 0.60`, `k = 0.75` → `z_start = 0.45`, `S = 0.30 m`. `g = 1.0 / (7 × 0.30) = 0.476` → each stroke reels `0.476 × 0.30 = 0.143 m` → 7 strokes ≈ 1.0 m.

**Case study (Rani's right arm).** `R_f,R = 0.42`, `k = 0.75`: `z_start = 0.315`, `S = 0.165 m`. `g = 1.0 / (7 × 0.165) = 0.866` (≤ 1) → each stroke reels `0.143 m`. Both arms need about 7 strokes even though her right stroke is shorter. Without per-hand gain her right arm would need 12 strokes.

### 6.5.3 Scoring hooks

- One completed stroke = hit (`13` §7.1). Finishing the debris early (before the round ends) gives `+100` **[P]**.

### 6.5.4 Safety and comfort

- No real resistance, so this trains movement and posture, **not strength**. Do not claim strength gains **[S]**.
- Keep shoulders down; no jerk: if hand speed > 1.5 m/s the stroke still counts but a soft cue says "slow and smooth" **[P]**.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Target strokes `N` | 7 **[P]** | |
| Debris distance `D` | 1.0 m **[P]** | |
| Stroke window `T_s` | 2.0 s **[P]** | |
| `z_end` | 0.15 m **[P]** | |
| Rumble amplitude | 0.15 **[P]** | |

## Open questions

1. Both hands on one big handle, or two separate tethers?
2. Should drift-back be visible (rope slackens) or instant reset?
3. Is "grab with grip button" acceptable, or touch-only?
