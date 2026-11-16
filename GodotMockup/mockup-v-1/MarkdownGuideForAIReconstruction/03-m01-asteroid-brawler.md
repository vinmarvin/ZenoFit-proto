# M01 — Seated Boxing ("Asteroid Brawler")

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.1 Seated Boxing — "Asteroid Brawler"

| Item | Spec |
|---|---|
| Real movement | Light forward punches, alternating or free |
| Body area / group | Chest and arms (light cardio) · **Chest/arms** |
| Safety level | A (arms only) |
| Priority | **P0** (vertical slice) |
| Calibration | Base calibration only (`R_f` per hand) |
| Feeling | Empowering, rhythmic |
| Source | **[D]** concept; Beat-Saber-style beat matching is a reference to verify **[V]** |

### 6.1.1 Gameplay

- Asteroids spawn ahead of the user and fly toward them **on the beat** (tempo from `02` §6.B). Punch to shatter them.
- Any hand may hit an asteroid by default; an optional mode color-codes asteroids per hand.
- A missed asteroid bursts harmlessly **before** it reaches the user's face. No damage flash, no screen shake.
- Contact is a hit. Punch speed changes only the feedback strength, never the validity of the hit.

### 6.1.2 Geometry and formulas

```
z_hit    = k × R_f,hand                 // where the user meets the asteroid (BodyFrame)
z0       = 1.5 m                        // spawn distance [P]
t_lead   = 1.0 s                        // flight time, so it arrives on the beat [P]
v_a      = (z0 − z_hit) / t_lead        // speed chosen per asteroid
z_miss   = 0.20 m                       // asteroid bursts here if not hit
speed v  = |hand_pos(t) − hand_pos(t−Δt)| / Δt   (smoothed over 3 frames)
v ≥ v_solid (0.30 m/s) → solid hit; else light hit (both score)
```

**Simple problem.** `R_f = 0.60 m`, `k = 0.85` → `z_hit = 0.51 m`. With `z0 = 1.5 m` and `t_lead = 1.0 s`: `v_a = (1.5 − 0.51) / 1.0 = 0.99 m/s`.

**Case study (Rani).** `R_f,L = 0.55`, `R_f,R = 0.42`, `k = 0.75`: `z_hit,L = 0.4125 m`, `z_hit,R = 0.315 m`. To make both asteroids arrive on the beat:
`v_L = (1.5 − 0.4125)/1.0 = 1.0875 m/s`, `v_R = (1.5 − 0.315)/1.0 = 1.185 m/s`. Speeds differ per hand so rhythm stays identical.

### 6.1.3 Scoring hooks

- Base points and timeliness: `13-scoring-and-score-attack.md` §7.1. Solid hit: `+25` **[P]**.
- Hit sphere radius: per preset (`00-gameplay-overview.md` §5.3).

### 6.1.4 Safety and comfort

- Punches are forward only. `z_hit ≤ 0.85 × R_f` **[S]**. No lunging or leaning is needed or rewarded.
- Asteroids never travel closer than `z_miss` to the face (avoids jump-scare and flinch).
- Haptics: solid 0.70 / 80 ms, light 0.20 / 30 ms (`15-feedback-and-ui.md` §9.1).

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Spawn distance `z0` | 1.5 m **[P]** | |
| Lead time `t_lead` | 1.0 s **[P]** | |
| `v_solid` | 0.30 m/s **[P]** | |
| Touch mode (every contact = solid) | optional **[P]** | |
| `z_miss` | 0.20 m **[P]** | |
| Spread of spawn lanes | ±0.10 m **[P]** | |
| Color-coded hands | off **[P]** | |

## Open questions

1. Single lane in front, or a small arc (±20°) so punches vary?
2. Should combos (L-R-L) exist, or single punches only?
3. Music-driven beat or a simple metronome?
