# Safety System

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 8. Safety system `GP-SAFE-*` **[S]**

### 8.1 Auto-pause when hands rest in the lap
```
lapDistance(hand) = |handTip − LapPoint|
if both hands have lapDistance ≤ 0.15 m for ≥ 2.0 s → Pause + passthrough [P distance, S time]
```
**Simple problem.** The calibrated `LapPoint` is 0.45 m below the chest. Both hands move to within 0.12 m of that point and stay for 2.0 s. `0.12 ≤ 0.15` and `2.0 ≥ 2.0` → the game freezes and passthrough opens (or the fallback pause scene shows).
- If `SupportsPassthrough = false`, show the fallback scene: a static calm scene with the "Resume / Stop" panel.

### 8.2 Manual pause / stop
- The controller **menu button** pauses at any time. A big, always-reachable *Stop* is on the pause panel.
- The pause panel is positioned at a comfortable distance (≈ 1.0 m ahead, at eye level, slightly below) and uses a **ray pointer** or a dwell/touch-friendly large button. **[P]**

### 8.3 Rest reminder
Every **8 minutes** [P; range 7–10 **[S]**]: auto-pause, show a "Relax your shoulders and neck" message (headset weight, about 500 g **[S]**), resume when the user confirms.

### 8.4 Lean / balance warning `GP-SAFE-LEAN-01` **[P]**
Lateral lean: `Δx = x_head − x_SeatAnchor` (in BodyFrame). If `|Δx| > 0.20 m` for ≥ 0.5 s → soft pause + message "Please sit back in a stable position."
**Simple problem.** Δx = 0.12 m → no warning. Δx = 0.22 m for 0.6 s → warning.
This addresses the reported risk of users tilting toward virtual motion and falling from a wheelchair. **[S]** (The app has no virtual motion at all, per G4, so this is a second safety layer.)

### 8.5 Reach and angle guards
- Targets: `k ≤ 0.85`, `θ ≤ 70°` (default 60°) (see §4.3, §6.3).
- No target may require standing, leaning, or crossing outside the BodyFrame envelope.

### 8.6 Visual comfort (cybersickness) `GP-COMFORT-01` **[S]**
- Camera = fixed anchor. No smooth camera motion, no moving environment that suggests self-motion.
- If background motion exists, add static reference elements (e.g. a fixed floor/cockpit).
- Calm lighting; high contrast for readability.

### 8.7 Deferred (documented, not built)
Heart-rate integration and the HR safety cut-off. For reference only, using the PDF's formula (unverified **[V]**): `HRpeak = 220 − age − 20`. **Simple problem:** age 30 → `220 − 30 − 20 = 170 bpm`; the moderate zone 75 %–86 % → `0.75 × 170 = 127.5 bpm` to `0.86 × 170 = 146.2 bpm`.

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Lap-rest distance | 0.15 m **[P]** | |
| Lap-rest hold time | 2.0 s **[S]** | |
| Rest reminder interval | 8 min (range 7–10 **[S]**) | |
| Lean threshold (lateral) | 0.20 m for 0.5 s **[P]** | |
| Resume countdown | 3 s **[P]** | |
| Max reach factor | 0.85 **[S]** | |

## Open questions

1. Who reviews the safety defaults (physiotherapist/clinician) before user tests?
2. Should the app show a one-time safety notice ("not a medical device") at first launch?
