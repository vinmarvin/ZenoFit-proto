# Exercise: Side Arm Raise

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 6.3 Side Arm Raise — complexity: Medium **[S]**

Side targets are placed around the **shoulder**, using the angle of the arm from the body's vertical axis.

```
θ  = abduction angle from the body axis (0° = arm hanging down, 90° = horizontal)
r  = k × L_arm                                      // distance from the shoulder
x_offset = ± r × sin(θ)        (+ for right, − for left, relative to that shoulder)
y_offset =   − r × cos(θ)      (negative = below shoulder level)
θ ≤ θ_max   with θ_max default 60°, hard cap 70°    [S: 60°–70°]
```

**Simple problem.** Arm length `L = 0.60 m`, `k = 0.85`, `θ = 60°`.
`r = 0.85 × 0.60 = 0.51 m`
`x_offset = 0.51 × sin 60° = 0.51 × 0.866 = 0.442 m` outward from the shoulder
`y_offset = −0.51 × cos 60° = −0.51 × 0.5 = −0.255 m` (25.5 cm *below* the shoulder)
So the target is a bit below shoulder height, well within the 60° limit.

**Case study.** *Rani's* right arm: `L_R = 0.52 m`, Standard preset `k = 0.75`, `θ = 45°`.
`r = 0.75 × 0.52 = 0.39 m`; `x = 0.39 × 0.707 = 0.276 m`; `y = −0.39 × 0.707 = −0.276 m`.
The system places the right target 27.6 cm to the right of her right shoulder and 27.6 cm below it. Before spawning, it checks the target is not within `0.12 m + radius` of the right armrest/wheel exclusion sphere (§4.5). If it is, θ is reduced (e.g. 45° → 40°) until it clears.

| Item | Spec |
|---|---|
| Position | Per formula; target at the *hand's side*. Angles in `[20°, θ_max]` **[P]**. |
| Pattern | Left/right targets alternate or random per hand mode. |
| Hit rule | Hand tip enters target sphere. |
| Safety | θ never exceeds `θ_max`; slow tempo only (≤ 60 BPM default) **[P]** because this exercise loads the shoulder. |

`GP-SIDE-01` Side targets MUST be rejected if they violate the exclusion zones or θ limit.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Max abduction angle `θ_max` | 60° default, hard cap 70° **[S]** | |
| Minimum angle | 20° **[P]** | |
| Tempo cap | 60 BPM **[P]** | |
| Arm length source | measured in calibration (`L_arm`) **[P]** | |
| Exclusion radius | 0.12 m **[P]** | |

## Open questions

1. Should the angle gradually increase during a round, or stay constant?
2. Is a physiotherapist available to confirm the 60° default before user tests?
3. Theme idea: reaching for lanterns/stars on each side?
