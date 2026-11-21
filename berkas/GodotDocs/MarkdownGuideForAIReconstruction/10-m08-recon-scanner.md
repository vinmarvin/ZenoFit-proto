# M08 — Neck Mobility and Far Focus ("Recon Scanner")

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.
> Shared rules for every mechanic (targets, adaptive tempo, hit detection): `02-targets-and-hit-detection.md`.

---

## 6.8 Neck Mobility and Far Focus — "Recon Scanner"

| Item | Spec |
|---|---|
| Real movement | Slow head turns to scan a horizon; optional far-look break |
| Body area / group | Neck, eyes · **Neck & shoulders** |
| Safety level | **B** (neck movement) |
| Priority | P2 |
| Calibration | Base + **Neck module** (comfortable turn left/right) |
| Feeling | Relaxing and observant |
| Source | **[P]**; the draft said "gaze tracking", changed to head pointing (see note) |

### 6.8.1 Gameplay

- A distant horizon contains camouflaged targets. Turn the head slowly so the **head reticle** rests on a target to scan it.
- **Note:** Quest 2/3/3S have no eye tracking (Quest Pro does) **[V]**, so the reticle follows head direction, not gaze.
- Optional **Far-look break** (20 s): passthrough opens and the app asks the user to look at something far away in the real room. Quest 2 passthrough is black-and-white **[V]**.

### 6.8.2 Geometry and formulas

```
Neck calibration: look left as far as comfortable → ψ_n,L; right → ψ_n,R   (head yaw in BodyFrame)
target yaw   ψ_t = ± k × ψ_n,max,side;   pitch within ±20°;   distance D = 10 m [P]
scan         reticle error ≤ 3°  AND  head angular speed ω_h ≤ 60°/s  for 1.0 s
```

**Simple problem.** `ψ_n,R = 70°`, `k = 0.75` → `ψ_t = 52.5°`. The user must rest the reticle within 3° of that direction, turning slower than 60°/s, for 1.0 s. A turn of 52.5° at 60°/s takes about `52.5 / 60 = 0.9 s`.

**Case study.** If the user turns at 90°/s the dwell timer **pauses** (not resets) and a soft "slower" cue appears. Slow movement is what is rewarded, which is the opposite of a reflex shooter.

### 6.8.3 Scoring hooks

- Target scanned = hit (`13` §7.1). Smoothness bonus: `+10` if ω_h stayed ≤ 60°/s during the scan **[P]**.

### 6.8.4 Safety and comfort

- Head pitch ≤ +20° up (no neck extension). Max one round 30 s. Stop if dizzy (generic safety notice).
- **Do not claim eye-strain relief.** VR optics use a fixed focal distance, so virtual "far" objects do not make the eye focus far **[V]**. The far-look break uses the real room instead.
- Skipped in **No-trunk mode** only if the user also disables neck movement (`14` §8.8) **[P]**.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Dome distance `D` | 10 m **[P]** | |
| Reticle tolerance | 3° **[P]** | |
| Dwell time | 1.0 s **[P]** | |
| Head speed limit | 60°/s **[P]** | |
| Pitch limit | ±20° **[P]** | |
| Far-look break length | 20 s **[P]** | |

## Open questions

1. Do you want the far-look break to be mandatory once per session, or optional?
2. Should the head-tilt (ear-to-shoulder) variant be included?
3. Visual theme: night-vision/recon, or a calm nature scene?
