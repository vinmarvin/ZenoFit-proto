# M07 — Arm Circles ("Shield Generator Crank")

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.7 Arm Circles — "Shield Generator Crank"

| Item | Spec |
|---|---|
| Real movement | Slow circular arm motions at chest height |
| Body area / group | Shoulders, upper back posture · **Neck & shoulders** |
| Safety level | A (arms only) |
| Priority | **P0** (vertical slice) |
| Calibration | Base calibration only |
| Feeling | Focused, stabilizing (counters hunching) |
| Source | **[P]** |

### 6.7.1 Gameplay

- Two virtual cranks sit in front of the shoulders. Move each hand around its crank at a steady pace to keep the shield energy up.
- Direction alternates every 10 s (clockwise / counter-clockwise) to balance the shoulder **[P]**.
- Cranks sit slightly above chest level to encourage an upright posture.

### 6.7.2 Geometry and formulas

```
crank centre   C_c = ( ±0.22, +0.05, 0.40 ) m  (BodyFrame)          [P]
hand angle     θ = atan2(y_h − y_c, x_h − x_c)   (unwrap between frames)
cadence        f = |Δθ / Δt| / (2π)   Hz
on the circle  | dist(hand, C_c) − r | ≤ 0.06 m
in band        | f − f_target | ≤ 0.25 × f_target
shield energy  E += 10/s in band;  E −= 5/s out of band;  0 ≤ E ≤ 100
hand speed     v = 2π × r × f
```
`r` by preset: Gentle 0.12 m, Standard 0.18 m, Active 0.25 m; `f_target`: 0.5 / 0.75 / 1.0 Hz **[P]**.

**Simple problem.** `r = 0.18 m`, `f = 0.75 Hz` (45 rpm): `v = 2π × 0.18 × 0.75 = 0.848 m/s`.

**Case study.** Target `f = 0.75 Hz`. The user measures `0.90 Hz` → deviation `(0.90 − 0.75) / 0.75 = 20 %` ≤ 25 % → **in band**, energy rises. At `1.00 Hz` → `33 %` → out of band, energy falls.

### 6.7.3 Scoring hooks

- Score = seconds in band × 10 **[P]**; shield full (E = 100) gives `+100` once.

### 6.7.4 Safety and comfort

- Slow and controlled only (≤ 1.0 Hz). Direction switches every 10 s. Max 30 s per round.
- No overhead component; circles stay at chest height.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Crank centre | (±0.22, +0.05, 0.40) m **[P]** | |
| Radius `r` | 0.12 / 0.18 / 0.25 m **[P]** | |
| `f_target` | 0.5 / 0.75 / 1.0 Hz **[P]** | |
| Band tolerance | 25 % **[P]** | |
| Direction switch | every 10 s **[P]** | |
| Circle tolerance | 0.06 m **[P]** | |

## Open questions

1. One crank at a time or both hands together?
2. Should a metronome/visual pace marker guide the cadence?
3. Large "sunshine" circles (shoulder height) as an advanced level?
