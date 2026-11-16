# Exercise: Forward Arm Reach

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 6.1 Forward Arm Reach — complexity: Low **[S]**

| Item | Spec |
|---|---|
| Goal | Reach forward and touch a target. |
| Position | `x ∈ [−0.10, +0.10] m` (small jitter), `y ≈ 0` (chest level, ±0.05 m **[P]**), `z = k × R_f,hand`. |
| Pattern | One target at a time; hand assignment random or fixed by hand mode. |
| Hit rule | Hand tip enters the target sphere. |
| Feedback | Short, soft haptic + gentle "pop" + brief glow. |
| Tempo | Beat-based (default 60 BPM) but with generous lifetime. |

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Reach factor `k` | by difficulty preset (0.60 / 0.75 / 0.85) | |
| Horizontal jitter of target | ± 0.10 m **[P]** | |
| Vertical jitter of target | ± 0.05 m **[P]** | |
| Targets per round | 20 **[P]** | |
| Hand assignment | random, or fixed by hand mode **[P]** | |

## Open questions

1. Fixed positions per round (predictable) or random within a zone (varied)?
2. Should the target "float" slightly toward the user to encourage a full reach, or stay still?
3. Do you want a theme/story for this minigame (e.g. picking fruit, popping bubbles)?
