# Exercise: Seated Boxing

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 6.6 Seated Boxing — complexity: Medium **[S]**

| Item | Spec |
|---|---|
| Goal | Light punches at target pads on a gentle rhythm. |
| Position | Pad at `x = ±w/2` (as in 6.2) or centered, `y ≈ 0`, `z = k × R_f,hand`. |
| Tempo | Starts 60 BPM, adaptive (§6.4). |
| Hit rule | A hit counts on **contact**. Punch speed only changes *feedback strength* (below). No penalty for slow motion and **no maximum speed**. |
| Speed | `v = |hand_pos(t) − hand_pos(t−Δt)| / Δt`, smoothed over the last 3 frames. |
| Feedback | `v ≥ v_solid` (default **0.30 m/s [P]**) → "solid" hit: stronger, slightly longer haptic. `v < v_solid` → "light" hit: very soft haptic. Both give points. **[S]** |
| Alternate mode | "Touch mode": `v_solid = 0` so every contact is a solid hit (for users with limited arm speed). **[P]** |

**Simple problem.** The hand tip moves 0.04 m between two frames spaced 0.1 s apart. `v = 0.04 / 0.1 = 0.4 m/s`. Since `0.4 ≥ 0.30`, this is a **solid** hit. If it had moved 0.02 m in 0.1 s: `0.2 m/s < 0.30` → **light** hit (still scores).

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Solid-hit speed `v_solid` | 0.30 m/s **[P]** | |
| Touch mode (every contact = solid) | optional setting **[P]** | |
| Solid-hit bonus | +25 points **[P]** | |
| Pad layout | split left/right or centered **[P]** | |
| Solid / light haptic | 0.70 for 80 ms / 0.20 for 30 ms **[P]** | |

## Open questions

1. Do you want a virtual coach/trainer character, or just pads and rhythm?
2. Should combos (e.g. L-R-L) exist, or keep single punches only?
3. Music-driven rhythm (like Beat Saber style) or a simple metronome?
