# Safety System (v0.4 — Hybrid Hand Tracking & Zen Dojo)

> Part of the **ZenoFit AI Reconstruction Spec Pack (Godot 4.7)**. **Section numbers are global across all gameplay files**. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** source/research · **[D]** locked team decision · **[P]** tunable default · **[V]** verify on hardware.

---

## 8. Safety system `GP-SAFE-*` **[S][D]**

### 8.1 Auto-pause when hands rest in the lap (`AT-09`)
```text
lapDistance(hand) = |handTip - LapPoint|
if both hands have lapDistance <= 0.15 m for >= 2.0 s -> Pause + Passthrough
```
- **Hand-Tracking Camera FoV Fallback (`GP-SAFE-HT-01`) [D]:** When optical Hand Tracking is active, lowering both hands to the lap may cause hands to exit the headset camera's downward FoV (`is_tracked == false`). If both hands were last observed moving downward in the lower zone (`y <= -0.25 m` in BodyFrame) and then lose tracking continuously for `>= 2.0 s`, `AutoPauseMonitor` MUST still trigger `AUTO_PAUSE_LAP` + `Platform.set_passthrough(true)`.
- If `Platform.supports_passthrough() == false`, display the calm Zen Dojo pause scene with *Resume / Stop*.

### 8.2 Manual pause / stop (`AT-14`)
- **Controller mode:** `menu_button` pauses within 1 frame and freezes beat/round timers.
- **Hand Tracking mode:** Open palm-up hold (`1.5 s` facing headset) or tapping a persistent corner *Pause* badge pauses within 1 frame.
- Resume ALWAYS runs a **`3.0 s` countdown** (`GP-FLOW-02`).

### 8.3 Rest reminder & Extended-session Zen Breather
- **Continuous play timer:** Every **8 minutes** [P; range 7–10 **[S]**] of active play, auto-pause and show *"Relax your shoulders and neck from the headset weight."*
- **Extended sessions (`6 min` / `10 min`):** Automatically insert a **`20–30 s` Zen Breather (Passthrough ON)** between 5-round stages to mitigate neck load (~500 g headset) and peripheral/sopite motion sickness (Xu et al., 2020).

### 8.4 Lean / balance warning `GP-SAFE-LEAN-01` (`AT-10`)
- Lateral lean: `Δx = x_head - x_SeatAnchor` (BodyFrame).
- **Level A mechanics:** If `|Δx| > 0.20 m` for `>= 0.5 s` → soft pause + *"Please sit back in a stable position."*
- **M10 Bamboo Sway (`Level B`):** Overrides threshold to `min(|Δx_max| + 0.05, 0.30) m`.

### 8.5 Reach, Scapular Plane, & Angle Guards
- Reach factor hard cap: `k <= 0.85` (`ComfortProfile.MAX_REACH_FACTOR_K`).
- **Scapular plane (`M03`):** Position lateral wings `15°–30°` forward of the side plane to protect the shoulder joint and keep optical hand tracking inside camera FoV.
- Module caps: `M04` twist `<= 60°`, `M08` neck yaw `<= 65°` & speed `<= 60 deg/s`, `M10` lean gap `<= 0.25 m`.

### 8.6 Visual comfort (cybersickness) `GP-COMFORT-01` **[S][D]**
- Fixed seated camera (`XROrigin3D` never translates, rotates, or rolls during gameplay).
- **Zen Dojo static reference frame:** Tatami grid lines, wooden pillars, and shoji frames stay completely stationary to anchor spatial orientation and minimize peripheral/sopite sickness (Flatlandsmo, 2023; Xu et al., 2020).
- Maintain locked **72–90 FPS** (see `03-godot-build.md` §5 render budget).

### 8.7 Mechanic Safety Levels, Chair Check, & No-Trunk Mode `GP-SAFE-LVL-01` (`AT-26`, `AT-28`)

| Level | Meaning | Mechanics | Extra Rules |
|---|---|---|---|
| **A** | Arms only | `M01, M02, M03, M05, M06, M07, M09` | Generic lean warning (`0.20 m`) active; speed/timeliness scoring allowed. |
| **B** | Trunk or neck | `M04, M08, M10` | Requires stable chair; **precision/smoothness scoring ONLY** (no speed bonus); never consecutive in a draw. |

- **Chair Type Check during Calibration [D]:** Ask *"Sitting on a stable chair (no wheels / locked)?"* Selecting **Swivel / Rolling Chair** automatically enables **`No-Trunk Mode`** (`Level A` only).
- **Mid-Session Stable-Chair Gate (`AT-28`):** If not confirmed yet before the first `Level B` round, pause and prompt; declining substitutes an unused `Level A` mechanic.
- **First-Launch Non-Medical Notice:** *"ZenoFit is an active-break VR game, not a medical device. Stay seated, move within your comfort, and stop immediately if anything hurts or feels dizzy."*

---

## Tunables

| Parameter | Default |
|---|---|
| Lap-rest distance / hold time | `0.15 m` / `2.0 s` **[P][S]** |
| Hand-tracking FoV drop-to-lap timeout | `2.0 s` after last `y <= -0.25 m` **[P]** |
| Rest reminder interval | `8 min` (range `7–10`) **[P][S]** |
| Extended Zen Breather duration | `20 s` (`6 min`) / `30 s` (`10 min`) **[P]** |
| Lateral lean threshold (Level A) | `0.20 m` for `0.5 s` **[P]** |
| Resume countdown | `3.0 s` **[P]** |
| Max reach factor `k` | `0.85` **[S]** |
