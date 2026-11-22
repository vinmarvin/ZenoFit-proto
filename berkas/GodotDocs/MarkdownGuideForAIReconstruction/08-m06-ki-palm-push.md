# M06 — Forward Press ("Ki Palm Push")

> [!IMPORTANT]
> **v0.4 Zen Dojo Arcade Revision (`godot/mechanics/m06_ki_palm_push/m06_mechanic.gd`):**
> - **Zen Dojo Theme:** Open-palm push against a heavy *shoji* / *Ki* energy barrier (`2.0 s` isometric charge → release wave). Update UI title to `"M06: Ki Palm Push (Forward Press)"`.
> - **Anti-Cheat Fix (`AT-32`, `GP-ANTI-CHEAT-01`):** Add mandatory **retract hysteresis**—after releasing a blast and finishing the `1.0 s` cooldown, active hand(s) MUST retract behind `z_plane - 0.10 m` before the next charge can begin (blocks keeping arms locked forward permanently).
> - **Hybrid Input & Juice:** Works with Hand Tracking open-palm push and Controller (`NO raycast`). Play rising *Ki* hum + crisp *shoji* burst SFX on release.

> Part of the spec pack (Godot 4.7 · PICO 4 Ultra & Meta Quest). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.6 Forward Press — "Ki Palm Push"

| Item | Spec |
|---|---|
| Real movement | Push one or both hands forward and hold briefly |
| Body area / group | Chest, front shoulders, triceps · **Chest/arms** |
| Safety level | A (arms only) |
| Priority | **P0** (vertical slice) |
| Calibration | Base calibration only (`R_f` per hand) |
| Feeling | Powerful and explosive |
| Source | **[D]** concept; forward press from the PDF **[S]** |

### 6.6.1 Gameplay

- A heavy blast door (or energy beam) sits ahead. Press forward and **hold** to charge; release to blast.
- Two-hand mode: both hands must press together. One-hand mode is available.
- Releasing early lowers the charge slowly (no penalty).

### 6.6.2 Geometry and formulas

```
z_plane   = k × R_f                 // two hands: use the SMALLER R_f so both can press
d_p       = 0.03 m                  // press depth to register
hold      : charge = min(1, t_hold / T_full),   T_full = 2.0 s,  max hold 3 s
sync bonus if |z_left − z_right| ≤ 0.05 m while holding
points    = round(100 × charge)  (+25 if synchronized)
```

**Simple problem.** The user holds for `t_hold = 1.5 s`, `T_full = 2.0 s` → `charge = 1.5 / 2.0 = 0.75` → `100 × 0.75 = 75` points.

**Case study (Rani, two-hand mode).** `R_f,L = 0.55`, `R_f,R = 0.42`, `k = 0.75` → plane at `0.75 × min(0.55, 0.42) = 0.315 m`. Both hands push the same plane. The left arm presses well within its comfort limit and the right arm is not over-reached.

### 6.6.3 Scoring hooks

- Charge points and sync bonus above. A full charge in under 2.0 s is not possible by design. Fixed `T_full` keeps pacing safe.

### 6.6.4 Safety and comfort

- Max hold 3 s, then forced release with a 1 s cooldown. No shoulder shrug required.
- Press haptic: 0.40 / **50 ms** **[S]** (`15` §9.1). Soft click audio.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Press depth `d_p` | 0.03 m **[P]** | |
| `T_full` | 2.0 s **[P]** | |
| Max hold | 3 s **[P]** | |
| Sync window | 0.05 m **[P]** | |
| Sync bonus | +25 **[P]** | |
| Cooldown | 1 s **[P]** | |

## Open questions

1. Door opening or beam attack as the main fantasy?
2. Should a single press (no hold) exist as an easy mode?
3. Do both hands need to press together to open the door?
