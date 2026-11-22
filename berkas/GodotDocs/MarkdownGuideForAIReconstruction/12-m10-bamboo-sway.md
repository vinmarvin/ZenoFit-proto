# M10 — Overhead Reach with Side Bend ("Bamboo Sway")

> [!IMPORTANT]
> **v0.4 Zen Dojo Arcade Revision (`godot/mechanics/m10_bamboo_sway/m10_mechanic.gd` — Level B, FIX PARTIAL):**
> - **Zen Dojo Theme:** Holding a diagonal overhead bamboo *bo staff* and gently swaying the torso sideways like bamboo in the wind through approaching wind-screen gaps (`<= 0.25 m`). Update UI title to `"M10: Bamboo Sway (Side Bend)"`.
> - **Anti-Cheat Fix (`AT-34`, `GP-ANTI-CHEAT-01`):** Validate active hand(s) remain raised on the overhead rail (`y_hand >= y_rail - 0.15 m` in BodyFrame). If hands drop below the rail, **pause** the approaching wind wall and display a gentle hint (blocks head-only dodging with hands in lap).
> - **Level B Scoring Rule (`GP-SCORE-07`):** Reward safe gap precision only; enforce `min(|Δx_max| + 0.05, 0.30) m` lean safety pause (`AT-10`, `AT-25`).

> Part of the spec pack (Godot 4.7 · PICO 4 Ultra & Meta Quest). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.10 Overhead Reach with Side Bend — "Bamboo Sway"

| Item | Spec |
|---|---|
| Real movement | Hold an overhead rail and lean the torso sideways into a gap |
| Body area / group | Lateral trunk, shoulders · **Back/trunk** |
| Safety level | **B** (trunk movement) |
| Priority | P2 |
| Calibration | Base + **Lean module** (comfortable sideways head offset left and right) |
| Feeling | Tense and evasive |
| Source | **[P]** |

### 6.10.1 Gameplay

- Both hands hold a virtual rail raised diagonally forward-up (same placement as §6.2 at `φ = 45°`). Hold with the grip button.
- Laser walls approach with a **gap** on the left or right. Lean the torso so the head is inside the gap while the wall passes.
- Releasing the rail shows a hint and pauses the wall (no penalty).

### 6.10.2 Geometry and formulas

```
Lean calibration: lean left as far as comfortable (hands on rail) → Δx_max,L; right → Δx_max,R   (head lateral offset from SeatAnchor)
gap centre   g = ± k × Δx_max,side           // hard cap 0.25 m
success      | x_head − g | ≤ 0.08 m  during the 1.0 s the wall passes
lean pause threshold for THIS mechanic = min(Δx_max + 0.05, 0.30) m   (overrides the generic 0.20 m of §8.4)
wall approach speed ≤ 0.5 m/s ; one lean held ≤ 3 s
```

**Simple problem.** `Δx_max,R = 0.28 m`, `k = 0.85` → `g = 0.85 × 0.28 = 0.238 m` (≈ 0.24 m, under the 0.25 m cap). The wall passes in 1.0 s; the user must keep the head within `0.08 m` of `x = +0.24 m` (between 0.16 m and 0.32 m).

**Case study (Rani).** `Δx_max,L = 0.30`, `Δx_max,R = 0.20`, `k = 0.75`: left gap at `−0.225 m`, right gap at `+0.15 m`. The pause threshold for the right side is `min(0.20 + 0.05, 0.30) = 0.25 m`.

### 6.10.3 Scoring hooks

- Wall dodged = hit (`13` §7.1). Staying centered between walls: no bonus **[P]**.

### 6.10.4 Safety and comfort

- **Stable chair confirmation** required. Hard cap 0.25 m gap offset; head roll ≤ 25° **[P]**.
- Lean must be an alternating, short hold (≤ 3 s). Max one round 30 s. Skipped in **No-trunk mode** (`14` §8.8).
- Hands on the rail keep the arms away from desk/armrests.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Gap cap | 0.25 m **[P]** | |
| Success tolerance | 0.08 m **[P]** | |
| Wall speed | ≤ 0.5 m/s **[P]** | |
| Max lean hold | 3 s **[P]** | |
| Head roll limit | 25° **[P]** | |
| Rail elevation `φ` | 45° **[P]** | |

## Open questions

1. Should the rail grip be required (grip button) or just hands near the rail?
2. One gap at a time, or alternating left-right rhythm?
3. Do you want a visible "safe zone" ghost showing the gap position?
