# Exercise: Forward Press

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 6.5 Forward Press — complexity: Low **[S]**

| Item | Spec |
|---|---|
| Goal | Press a virtual elastic button forward with one or both hands. |
| Position | Button plane at `z = k × R_f` (use the **smaller** `R_f` if both hands are enabled so both can press), centered `x ≈ 0`, `y ≈ 0`. |
| Mechanic | The button has a travel depth `d_p = 0.03 m` **[P]**. A press registers when a hand tip pushes it past `d_p` along +Z. The button springs back. The user must release before the next press (hysteresis). |
| Feedback | Soft click audio + short haptic of **50 ms** **[S]**. |
| Pattern | The button lights on beat; press within lifetime = hit. |

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Press travel depth `d_p` | 0.03 m **[P]** | |
| Click haptic duration | 50 ms **[S]** | |
| Release required before next press | yes **[P]** | |
| Two-hand mode reach | uses the smaller `R_f` of both hands **[P]** | |
| Beat-based or free-press? | beat-based **[P]** | |

## Open questions

1. One big button, or a panel of several buttons/doors at different heights?
2. Should both-hands-together presses be a special mode?
3. Theme idea: opening doors, pushing a boat away, pressing elevator buttons?
