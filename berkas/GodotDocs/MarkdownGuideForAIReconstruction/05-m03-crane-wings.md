# M03 — Side Arm Raise ("Crane Wings")

> [!IMPORTANT]
> **v0.4 Zen Dojo Arcade Revision (`godot/mechanics/m03_crane_wings/m03_mechanic.gd` — FIX PARTIAL):**
> - **Zen Dojo Theme:** Paper crane (*origami tsuru*) gliding through bamboo rings / *torii* gates. Update UI title to `"M03: Crane Wings (Side Arm Raise)"`.
> - **Anti-Cheat Fix (`AT-30`, `GP-ANTI-CHEAT-01`):** MUST validate BOTH: (1) lateral span `curr_right.x - curr_left.x >= 0.70 * calibrated_span` and (2) abduction angle within `preset.m03_abduction_theta_deg ± 15°` (using `MechanicsMath.m03_compute_wing_target_offset()`). Award `+10 pts/s` ONLY while valid (blocks hands-in-front-of-stomach cheat).
> - **Hand-Tracking FoV & One-Hand Mode:** Target plane sits `15°–30°` forward (*scapular plane*) so hands stay inside optical camera FoV. In `LEFT_ONLY` / `RIGHT_ONLY` mode, steer from single-arm elevation delta relative to shoulder target height instead of `curr_right - curr_left`.

> Part of the spec pack (Godot 4.7 · PICO 4 Ultra & Meta Quest). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.3 Side Arm Raise — "Crane Wings"

| Item | Spec |
|---|---|
| Real movement | Raise both arms out to the sides (lateral raise) and tilt arm height slightly |
| Body area / group | Shoulders · **Neck & shoulders** |
| Safety level | A (arms only) |
| Priority | P1 |
| Calibration | Base calibration only (`L_arm`, shoulder points) |
| Feeling | Free and fluid |
| Source | **[D]** concept; side raise from the PDF **[S]** |

### 6.3.1 Gameplay

- Raising both arms deploys the glider wings. Rings come toward the user; steer to fly through them.
- **Steering uses arm height difference, not leaning the body.** The torso stays still.
- The user stays still. Rings approach along +Z (see comfort rules). The camera never moves or rolls.

### 6.3.2 Geometry and formulas

```
θ        = abduction angle from the body axis (0° = arm hanging, 90° = horizontal)
r        = k × L_arm
hand_x   = ± r × sin(θ)         (relative to that shoulder)
hand_y   =   − r × cos(θ)       (negative = below shoulder)
wings_ok : |θ − θ_target| ≤ 15°  for both arms
roll     = atan2(y_R − y_L, x_R − x_L)             // degrees
v_lat    = K × roll   with K = 0.10 (m/s)/deg      // lateral glide, ring offsets ±0.5 m
```
θ_target by preset: Gentle 60°, Standard 75°, Active 90° (hard cap 90°) **[P]**. (The original PDF's 60–70° cap was for wheelchair users; the desk audience can reach higher.)

**Simple problem (steering).** Left hand `y = 0.00 m`, right hand `y = +0.10 m`, hands 1.00 m apart: `roll = atan(0.10 / 1.00) = 5.7°` → `v_lat = 0.10 × 5.7 = 0.57 m/s`. A ring 0.5 m to the right is reached in about `0.5 / 0.57 = 0.9 s`.

**Case study (target position).** `L_arm = 0.60`, `k = 0.85`, `θ = 60°`: `r = 0.51`; `x = 0.51 × 0.866 = 0.442 m`; `y = −0.51 × 0.5 = −0.255 m` below the shoulder.

### 6.3.3 Scoring hooks

- Ring passed = hit (`13` §7.1). Wings-level bonus: `+10` per second inside tolerance **[P]**.

### 6.3.4 Safety and comfort

- Zero unintended locomotion: use a **fixed cockpit/wing reference** in view and only move rings toward the user (≤ 1.5 m/s). Do not roll or pitch the world. Cybersickness strongly reduces enjoyment (SSQ vs PACES r = −0.817) **[S]**.
- `θ ≤ θ_target + 15°`, hard cap 90°. Obstacle exclusion zones apply (`01` §4.5).
- Slow tempo only; this loads the shoulder.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| `θ_target` | 60° / 75° / 90° by preset **[P]** | |
| Tolerance | ±15° **[P]** | |
| Steering gain `K` | 0.10 (m/s)/deg **[P]** | |
| Ring offset | ±0.5 m **[P]** | |
| Approach speed | ≤ 1.5 m/s **[P]** | |
| Wings-level bonus | +10 per s **[P]** | |

## Open questions

1. Do you want a 3D cockpit frame or only the wing model as the static reference?
2. Rings only, or also collectibles beside the rings?
3. Should one-arm mode (steering with one wing) exist?
