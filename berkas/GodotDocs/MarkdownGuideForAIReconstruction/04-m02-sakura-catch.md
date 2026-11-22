# M02 — Overhead Reach ("Sakura Catch")

> [!IMPORTANT]
> **v0.4 Zen Dojo Arcade Revision (`godot/mechanics/m02_sakura_catch/m02_mechanic.gd`):**
> - **Zen Dojo Theme:** Falling sakura blossoms & golden paper lanterns (`+50` bonus every 4th spawn). Update UI title to `"M02: Sakura Catch (Overhead Reach)"`.
> - **Anti-Cheat Fix (`GP-ANTI-CHEAT-01`):** Vary horizontal spawn offset slightly (`±0.08 m`) or require hand to dip below `y_catch - 0.12 m` between catches on the same hand so holding a hand permanently overhead cannot auto-farm.
> - **Hybrid Input & Juice:** Direct 3D hand-tip/palm contact (`NO raycast`); play soft *furin* wind-chime SFX with combo pitch escalation + sakura particle burst.

> Part of the spec pack (Godot 4.7 · PICO 4 Ultra & Meta Quest). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.2 Overhead Reach — "Sakura Catch"

| Item | Spec |
|---|---|
| Real movement | Reach diagonally up and forward to grab falling items |
| Body area / group | Shoulders, upper back · **Neck & shoulders** |
| Safety level | A (arms only) |
| Priority | P1 |
| Calibration | Base calibration only (uses arm length `L_arm` and shoulder points) |
| Feeling | Desperate vertical stretching |
| Source | **[P]** (my suggestion in the draft) |

### 6.2.1 Gameplay

- Glowing fruit drifts down a short column in front of the user. Touch it with the hand tip to harvest it before it passes the window.
- Rare golden fruit is worth more.
- The reach is **diagonal (forward and up)**, not straight overhead. This keeps the fruit visible without tilting the head far back.

### 6.2.2 Geometry and formulas

```
r         = k × L_arm                          // distance from the shoulder
x, y, z   = S.x,  S.y + r·sin(φ),  S.z + r·cos(φ)   // S = shoulder point; φ = elevation angle
fall      : v_f = 0.4 m/s,  window = ±0.25 m around the catch point → 0.5 / 0.4 = 1.25 s
gaze check: elevation_from_eye = atan((y − y_eye) / z)  must be ≤ 45°   // else reduce φ
```
φ by preset: Gentle 35°, Standard 45°, Active 55° **[P]**. Eye is assumed on the vertical axis through the chest at `y_eye = +0.25 m` and the shoulder at `y = +0.12 m` **[P]**.

**Simple problem.** `L_arm = 0.60`, `k = 0.85`, `φ = 45°`. `r = 0.51 m`; forward `= 0.51 × 0.707 = 0.361 m`; up `= 0.361 m`, so fruit `y = 0.12 + 0.361 = 0.481 m`.
Gaze check: `atan((0.481 − 0.25) / 0.361) = atan(0.640) = 32.6°` → OK (≤ 45°).

**Case study (Rani, stiffer right shoulder).** `L_R = 0.52`, `k = 0.75`, Gentle `φ = 35°`: `r = 0.39 m`; forward `= 0.39 × cos35° = 0.320 m`; up `= 0.39 × sin35° = 0.224 m`; `y = 0.344 m`. The right fruit sits lower and closer than the left, matching her limit.

### 6.2.3 Scoring hooks

- Harvest = hit (`13` §7.1). Golden fruit: `+50` bonus **[P]**.
- Fruit that exits the window is a miss (no penalty).

### 6.2.4 Safety and comfort

- `k ≤ 0.85`. Never require the hand above `φ = 55°`. Gaze elevation ≤ 45° so the neck is not forced into extension.
- Short window, no sustained overhead holds. Max 30 s per round.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Elevation `φ` | 35° / 45° / 55° by preset **[P]** | |
| Fall speed `v_f` | 0.4 m/s **[P]** | |
| Window half-height | 0.25 m **[P]** | |
| Gaze elevation limit | 45° **[P]** | |
| Golden fruit bonus | +50 **[P]** | |

## Open questions

1. One fruit at a time or two (left/right) together?
2. Should a basket/hand-cup visual appear, or just touching?
3. Any theme besides fruit (stars, lanterns)?
