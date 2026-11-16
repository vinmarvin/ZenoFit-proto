# Targets, Adaptive Tempo, and Hit Detection

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 6.A Shared rules for all mechanics

Shared rules for all exercises:

- A target is a **sphere trigger** with radius from the preset. Its color shows which hand must touch it (e.g. blue = left, orange = right, white = either). Do not rely on color alone: add a hand icon/ring shape. **[P]**
- Targets appear on a **beat** and disappear after lifetime `L` beats. Touching in time = **hit**; expiring = **miss** (no penalty beyond no points).
- Hit detection: see §6.C.
- All distances below are in **BodyFrame**.

---

## 6.B Adaptive tempo (used by rhythm mechanics: §6.1 and any mechanic that spawns on a beat)

```
interval_s       = 60 / BPM                 // seconds between targets
window           = last 8 targets
accuracy         = hits / targets_in_window
if accuracy ≥ 0.85 → BPM += 5              (never above preset max)
if accuracy < 0.60 → BPM −= 5              (never below 40)
otherwise          → hold
```

**Simple problem.** At 60 BPM, `interval = 60 / 60 = 1.0 s` per target. If targets alternate between hands, each hand moves every 2.0 s. At 75 BPM: `60 / 75 = 0.8 s`; each hand every 1.6 s.

**Case study.** Session starts at 60 BPM (Standard).
- Window 1: 7 hits of 8 → 87.5 % → **65 BPM**
- Window 2: 6 hits of 8 → 75 % → hold **65 BPM**
- Window 3: 4 hits of 8 → 50 % → **60 BPM**
Tempo rose only when accuracy was stable, and fell when the user struggled. **[S]** (tempo increases only when accuracy is stable)

---

## 6.C Hit detection (shared) `GP-HIT-01`

At 72 Hz a fast hand can move several centimetres per frame and "tunnel" through a small sphere. Therefore:

1. Each frame, build the **segment** from the hand tip's previous position `P0` to current position `P1`.
2. Compute the shortest distance from the target center `T` to that segment.
3. If `distance ≤ targetRadius + handTipRadius` → hit.

Use `OnTriggerEnter` only as a fallback. Hit detection MUST use positions in BodyFrame/world consistently and MUST ignore hands that are disabled.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Adaptive window size | 8 targets **[P]** | |
| Raise tempo when accuracy ≥ | 0.85 **[P]** | |
| Lower tempo when accuracy < | 0.60 **[P]** | |
| Tempo step | 5 BPM **[P]** | |
| Minimum tempo | 40 BPM **[P]** | |
| Hand-tip collider radius | 0.04 m **[P]** | |
| Target color code (left / right / either) | blue / orange / white **[P]** | |

## Open questions

1. Should a missed target disappear silently, or fade with a soft cue?
2. Should the beat be audible (metronome / music) or purely visual?
