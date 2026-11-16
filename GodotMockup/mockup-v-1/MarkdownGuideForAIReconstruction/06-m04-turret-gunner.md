# M04 — Trunk Twist ("Turret Gunner")

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.4 Trunk Twist — "Turret Gunner"

| Item | Spec |
|---|---|
| Real movement | Rotate the upper body left/right while keeping hands close to the chest |
| Body area / group | Spine, obliques · **Back/trunk** |
| Safety level | **B** (trunk movement) |
| Priority | P2 |
| Calibration | Base + **Twist module** (comfortable twist angle left and right) |
| Feeling | Frantic awareness |
| Source | **[P]** |

### 6.4.1 Gameplay

- The user holds both controllers together like a turret handle. Enemies appear at angles to the left and right.
- Rotate the **torso** to aim; the aim ray comes from the midpoint of both controllers. Aim lock for 0.3 s fires automatically (trigger press is an optional alternative).
- Hands must stay within 0.35 m of the chest point. This makes the aim angle mostly come from torso rotation, not arm swinging.

### 6.4.2 Geometry and formulas

```
Twist calibration: hold controllers together at the chest, turn left as far as comfortable → ψ_max,L; right → ψ_max,R
aim yaw      ψ = atan2(mid.x, mid.z)           // mid = midpoint of both controllers, BodyFrame
target yaw   ψ_t = ± k × ψ_max,side            // hard cap 60°
target pos   x = D·sin(ψ_t),  z = D·cos(ψ_t)   // D = 1.5 m
lock         |ψ − ψ_t| ≤ 6° for 0.3 s
```

**Simple problem.** `ψ_max,L = 50°`, `k = 0.85` → `ψ_t = 42.5°`. At `D = 1.5 m`: `x = 1.5 × 0.6755 = 1.013 m`, `z = 1.5 × 0.7373 = 1.106 m`. If the user aims at `40°`, the error is `|40 − 42.5| = 2.5° ≤ 6°` → lock.

**Case study.** `ψ_max,L = 50°`, `ψ_max,R = 40°`, `k = 0.75`: left targets at `37.5°`, right at `30°`. The asymmetry is respected automatically.

### 6.4.3 Scoring hooks

- Lock-and-fire = hit (`13` §7.1). No timeliness bonus above 1.0 s **[P]**.

### 6.4.4 Safety and comfort

- **Stable chair confirmation** is required before this mechanic starts (no wheels or swivel locked) **[P]**.
- Hard cap 60°; `k ≤ 0.85` of the calibrated twist. Soft hint if aim yaw speed > 180°/s for > 0.3 s ("slow down"). No penalty.
- Hips and legs stay still. Limit one round to 30 s. Skipped entirely in **No-trunk mode** (`14-safety.md` §8.8).
- Limitation: torso rotation cannot be measured directly with controllers; the chest-distance rule is a proxy **[V]**.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Target distance `D` | 1.5 m **[P]** | |
| Aim tolerance | 6° **[P]** | |
| Lock time | 0.3 s **[P]** | |
| Hands-to-chest limit | 0.35 m **[P]** | |
| Hard angle cap | 60° **[P]** | |
| Auto-fire vs trigger | auto-fire **[P]** | |

## Open questions

1. Enemies one at a time or two at once (left and right)?
2. Should the turret be shown as a 3D object around the user?
3. Is a swivel-chair warning enough, or require an explicit checkbox each session?
