# ZenoFit (Godot 4.x) — Technical Design Document (TDD)

**Project**: ZenoFit Seated VR Exergame Mockup (`mockup-v-1`)  
**Engine**: Godot Engine 4.x (`gl_compatibility` / Mobile OpenXR)  
**Target Platforms**: **PICO 4 Ultra** (Standalone Android OpenXR + PICO Connect / WiVRn / ALVR PCVR), Meta Quest 2 / 3 / 3S, and Desktop Mouse-Keyboard Simulator  
**Non-Clinical Disclaimer**: *ZenoFit is a seated VR fitness and wellness game. Not a medical device. Stop if you feel pain, dizziness, or discomfort.*

---

## 1. Executive Summary & Core Design Goals

ZenoFit is a seated VR arcade fitness game designed around an individualized **Comfort Profile**, zero artificial locomotion, and strict physical safety boundaries. Every target position, angle, and threshold is derived mathematically from the player's calibrated seated posture rather than fixed world-space coordinates.

### Key Technical Pillars
1. **Seated Reference Space Only (`XR_REFERENCE_SPACE_TYPE_LOCAL`)**: The camera origin (`XROrigin3D`) is permanently stationary (`position == Vector3.ZERO`, `rotation == Vector3.ZERO`). Zero artificial camera translation, rotation, or shake is ever applied.
2. **Engine-Parity Coordinate Frame (`SpecSpace` ↔ `BodyFrame`)**: All specification equations use a left-handed `+Z` forward seated frame (`SpecSpace`) so every numerical formula matches the Unity specification 1-to-1, while `SpecSpace` converts seamlessly to and from Godot's right-handed `-Z` forward world space.
3. **Asymmetric & Obstacle-Aware Reach Envelope**: Left and right arms are calibrated independently (`R_f,L`, `R_f,R`, `R_oh,L`, `R_oh,R`, `R_s,L`, `R_s,R`). Chair armrests, tables, and trays are captured as 3D exclusion spheres (`r_ex = 0.12 m`) and automatically avoided at spawn time.
4. **Tiered Physical Safety (Level A vs. Level B)**:
   - **Level A (Upper-Limb Only)**: `M01`–`M07` require only shoulder, elbow, and wrist motion inside the seated frame.
   - **Level B (Trunk / Head / Balance)**: `M08` (Neck Yaw), `M09` (Trunk Rotation), and `M10` (Lateral Trunk Lean) require explicit stable-chair confirmation before activation, are never scheduled back-to-back in Score Attack, and are completely excluded when **No-Trunk Mode** is enabled.
5. **100% Controller-Free Gameplay**: Active rounds use only 6DoF head and hand poses (`HandTip_L` and `HandTip_R`) — no trigger, grip, or button presses are required during exercise rounds.

---

## 2. Coordinate System & Seated Body Frame (`BodyFrame`)

### 2.1 SpecSpace vs. Godot World Space
Implemented in [`core/spec_space.gd`](../core/spec_space.gd) and [`core/body_frame.gd`](../core/body_frame.gd):

| Axis / Quantity | Spec Space (`MarkdownGuideForAIReconstruction`) | Godot 3D Space (`Node3D`) | Conversion Formula (`SpecSpace`) |
| :--- | :--- | :--- | :--- |
| **Right (`X`)** | `+X` = Player's Right | `+X` = Right | `godot.x = spec.x` |
| **Up (`Y`)** | `+Y` = Up | `+Y` = Up | `godot.y = spec.y` |
| **Forward (`Z`)** | `+Z` = Forward (in front of chest) | `-Z` = Forward | `godot.z = -spec.z` |
| **Yaw (`ψ`)** | `+ψ` = Clockwise from above (turn right) | `+rotation.y` = Counter-clockwise (turn left) | `godot_yaw = -spec_yaw` |

### 2.2 BodyFrame Construction
During Base Calibration Step 1 (Neutral Seated Pose), the system samples `p_head(t)` and `f_head(t)` over `2.0 s`:
- **Origin (`O_body`)**:
  $$O_{\text{body}} = \bar{p}_{\text{head}} - (0, h_{\text{neck}}, 0), \quad h_{\text{neck}} = 0.18\text{ m}$$
- **Forward Axis (`Z_body`)**: Horizontal projection of average head forward vector `f_head`:
  $$Z_{\text{body}} = \text{normalize}\big((\bar{f}_x, 0, \bar{f}_z)\big)$$
- **Up Axis (`Y_body`)**: `(0, 1, 0)`
- **Right Axis (`X_body`)**: `Y_body × Z_body` (in left-handed SpecSpace)

---

## 3. Calibration System & Comfort Profile

Implemented in [`calibration/calibration_controller.gd`](../calibration/calibration_controller.gd) and [`core/comfort_profile.gd`](../core/comfort_profile.gd).

### 3.1 Base Calibration (7 Steps — First-Time or Full Recalibration)
1. **Step 1 — Neutral Seated Pose (`2.0 s` hold)**:
   - Stability gate: `max ||p_head(t) - p_head_mean|| <= 0.03 m`.
   - Sets `O_body`, `Z_body`, and `p_head,0`.
2. **Step 2 — Rest / Lap Zone (`1.5 s` hold)**:
   - Records resting hand height:
     $$y_{\text{lap}} = \frac{y_{\text{hand},L} + y_{\text{hand},R}}{2} + 0.08\text{ m}$$
3. **Step 3 — Comfortable Forward Reach (`1.5 s` hold)**:
   - Measures `R_f,L` and `R_f,R` independently, clamped to `[0.25 m, 0.75 m]`.
4. **Step 4 — Comfortable Overhead Reach (`1.5 s` hold)**:
   - Measures `R_oh,L`, `R_oh,R` (`[0.25 m, 0.75 m]`) and max vertical offset `y_max,L`, `y_max,R` (`[0.15 m, 0.60 m]`).
5. **Step 5 — Comfortable Side Reach (`1.5 s` hold)**:
   - Measures `R_s,L`, `R_s,R` (`[0.20 m, 0.75 m]`).
6. **Step 6 — Armrest / Table / Wheelchair-Tray Check (`Optional`)**:
   - Captures obstacle points `c_i` in `BodyFrame`, storing exclusion spheres of radius `r_ex = 0.12 m`.
7. **Step 7 — Verification Tap**:
   - Spawns 3 test targets (Left, Center, Right) at `70%` reach (`k = 0.70`) to verify comfortable reachability before saving.

### 3.2 Returning-User Quick Check (`<= 15 s`)
1. **Seat Anchor Re-Center (`1.5 s` hold)**: Updates `O_body`, `Z_body`, and `p_head,0` while keeping saved reach distances.
2. **Single Confirmation Tap**: Spawns 1 center target at `(0, 0.10, 0.65 * min(R_f,L, R_f,R))` to verify alignment.

### 3.3 Module-Specific Calibrations (Level B)
- **Neck Rotation (`M08`)**: Captures comfortable left/right head yaw (`ψ_max,L`, `ψ_max,R`), clamped to `[15°, 55°]`.
- **Trunk Rotation (`M09`)**: Captures lateral sweep (`x_twist,L`, `x_twist,R`), clamped to `[0.15 m, 0.55 m]`.
- **Lateral Lean (`M10`)**: Captures left/right head displacement (`Δx_max,L`, `Δx_max,R`), clamped to `[0.08 m, 0.28 m]`.

### 3.4 Spawn Envelope Clamping & Obstacle Exclusion
All mechanic targets pass through `ComfortProfile.clamp_and_resolve_spawn(p, hand_mode, k)`:
1. **Radial Clamp**: Uses `k * R_dir,hand` where `k <= 0.85` (`0.65` Gentle, `0.75` Standard, `0.85` Active). For two-hand symmetric mechanics (`M03`, `M05`, `M06`, `M09`), uses `min(R_f,L, R_f,R)`.
2. **Vertical Clamp**: Enforces `y >= y_lap + 0.05 m` and `y <= y_max,hand`.
3. **Obstacle Exclusion**: If `||p - c_i|| < 0.12 m`:
   - First shifts `p.y` upward to `max(p.y, c_i.y + 0.12 m)`.
   - If that exceeds `y_max,hand`, widens the horizontal angle `θ` away from `c_i` in `5°` increments up to `±25°`.

---

## 4. Game Modes, Session Draw, & State Machine

### 4.1 High-Level State Machine (`GameFlowController`)
Implemented in [`autoload/game_flow.gd`](../autoload/game_flow.gd):

```
BOOT -> DISCLAIMER_GATE -> HOME_HUB
  ├── CALIBRATION (Base 7-Step or Quick Check)
  ├── PRACTICE_SELECT -> MODULE_CALIBRATION (if M08/M09/M10 uncalibrated) -> PRE_ROUND_COUNTDOWN -> ACTIVE_ROUND -> ROUND_SUMMARY
  └── SCORE_ATTACK_DRAW -> STABLE_CHAIR_CONFIRM (if Level B drawn) -> PRE_ROUND_COUNTDOWN -> ACTIVE_ROUND -> ROUND_INTERMISSION (x5) -> SESSION_SUMMARY
```

### 4.2 Balanced 5-Round Session Draw (`SessionDraw`)
Implemented in [`core/session_draw.gd`](../core/session_draw.gd):
- Mechanics are grouped into 3 functional pools:
  - **Pool 1 (`PUSH_STRIKE`)**: `M01`, `M06`, `M07`
  - **Pool 2 (`REACH_PULL`)**: `M02`, `M04`, `M05`
  - **Pool 3 (`CORE_POSTURE`)**: `M03`, `M08`, `M09`, `M10` (filtered to `[M03]` when `no_trunk_mode == true`)
- **Draw Algorithm**:
  1. Draws 1 mechanic from Pool 1, 1 from Pool 2, 1 from Pool 3, and 2 additional distinct mechanics from the remaining union.
  2. Applies weight `0.5` to any mechanic that appeared in `last_session_mechanic_ids`, `1.0` otherwise.
  3. **Level B Non-Consecutive Ordering**: Permutes the 5-mechanic sequence so no two Level B mechanics (`M08`, `M09`, `M10`) are adjacent.
  4. **Stable-Chair Declined Substitution**: If the user declines the pre-session stable-chair prompt, every Level B mechanic in the draw is automatically replaced with an unused Level A mechanic (`M01`–`M07`).

---

## 5. Mathematical Specification of the 10 Exercise Mechanics (`M01`–`M10`)

Pure math evaluators live in [`core/mechanics_math.gd`](../core/mechanics_math.gd); scene controllers live in [`mechanics/`](../mechanics/).

### `M01` — Asteroid Brawler (Forward Punching)
- **Level**: A | **Category**: `PUSH_STRIKE`
- **Spawn**: `z = 0.70 * R_f,h`, `x ∈ [-0.25 * R_s,h, +0.25 * R_s,h]`, `y ∈ [0.05, 0.30]`, alternating `L/R`.
- **Evaluation**: Segment-to-sphere anti-tunnelling check (`r = 0.11 m`) AND forward velocity `v_h · u_t >= v_min` (`0.45 / 0.65 / 0.85 m/s`).
- **Solid Hit Bonus**: `+25 pts` when `v_h · u_t >= 1.25 m/s`.

### `M02` — Space Fruit Harvester (Overhead & Cross-Body Reach)
- **Level**: A | **Category**: `REACH_PULL`
- **Spawn (`3-Step Pattern`)**:
  1. Ipsilateral Overhead (`y = 0.80 * y_max,h`)
  2. Ipsilateral Mid-Side (`x = ±0.75 * R_s,h`)
  3. Controlled Cross-Midline (`x = ∓min(0.18 m, 0.35 * R_s,h)`)
- **Evaluation**: Dwell inside `r_orb = 0.10 m` for `T_dwell` (`0.15 / 0.20 / 0.25 s`), then deposit into central basket `(0, y_lap + 0.12 m, 0.32 m)` within `r_basket = 0.16 m`.

### `M03` — Glider Pilot (Bilateral Arm Abduction / T-Pose Flight)
- **Level**: A | **Category**: `CORE_POSTURE`
- **Evaluation**: Normalized wing elevation for each arm:
  $$e_h = \text{clamp}\left(\frac{y_h - (y_{\text{lap}} + 0.08)}{(y_{\text{max},h} - 0.05) - (y_{\text{lap}} + 0.08)}, 0, 1\right)$$
  - Combined altitude `e_bar = 0.5 * (e_L + e_R)` must match gate altitude `g_k ∈ {0.25, 0.50, 0.75}` within `|e_bar - g_k| <= 0.18`.
  - Bilateral symmetry check: `|y_L - y_R| <= Δy_sym` (`0.16 / 0.12 / 0.09 m`).

### `M04` — Turret Gunner (Isometric Extended Reach Hold)
- **Level**: A | **Category**: `REACH_PULL`
- **Spawn**: Azimuth `θ ∈ [-35°, +35°]`, elevation `φ ∈ [-5°, +25°]`, distance `d = 0.70 * R_f,h`.
- **Evaluation**: Hold hand inside `r_aim = 0.12 m` until charge `c` reaches `T_hold` (`1.0 / 1.5 / 2.0 s`). Charge decays at `0.5 * dt` on exit (grace period without full reset).

### `M05` — Cosmic Tug-of-War (Rhythmic Bilateral Row Pull)
- **Level**: A | **Category**: `REACH_PULL`
- **Zones**: Grab front `z_front = 0.75 * min(R_f,L, R_f,R)` → Pull back to `z_back = 0.28 m`.
- **Evaluation**: Both hands start at `z >= z_front - 0.08 m`, pull backward (`v_z <= -0.25 m/s`) to `z <= z_back + 0.06 m` within `1.8 s`, maintaining synchronization `|z_L - z_R| <= 0.12 m`.

### `M06` — Force Blast (Synchronized Two-Hand Chest Push)
- **Level**: A | **Category**: `PUSH_STRIKE`
- **Zones**: Charge inside chest zone (`z <= 0.30 m`, `|x_h| <= 0.22 m`) for `0.20 s` → Push outward to `z_ext = 0.75 * min(R_f,L, R_f,R)`.
- **Evaluation**: Both hands cross `z >= z_ext - 0.06 m` with forward speed `v_z >= v_push` (`0.40 / 0.55 / 0.70 m/s`) and arrival timing gap `|t_L - t_R| <= Δt_sync` (`0.18 / 0.14 / 0.10 s`).

### `M07` — Shield Generator Crank (Circular Shoulder Circumduction)
- **Level**: A | **Category**: `PUSH_STRIKE`
- **Wheel Geometry**: Center `c_w = (±0.18 m, 0.12 m, 0.55 * R_f,h)`, wheel radius `r_w = min(0.18 m, 0.30 * R_s,h)` (`0.14 m` Gentle, `0.18 m` Standard/Active).
- **Evaluation**: Radial band `|ρ - r_w| <= 0.09 m`, depth band `|z - c_w.z| <= 0.12 m`. Accumulates signed angle `Θ += Δα` in required direction `s_dir ∈ {+1, -1}` (`360°` per revolution). Switches hand or direction every `N_switch = 3` revolutions.

### `M08` — Recon Scanner (Controlled Cervical Yaw Rotation)
- **Level**: B | **Category**: `CORE_POSTURE`
- **Target Yaw**: `ψ_t = s * k_yaw * ψ_max,dir` (`k_yaw = 0.60 / 0.70 / 0.80`), alternating Left (`s = -1`) → Center (`0°`) → Right (`s = +1`).
- **Evaluation**: Dwell within `|ψ_head - ψ_t| <= 6°` and pitch `|θ_head| <= 12°` for `T_scan` (`0.50 / 0.70 / 0.90 s`).
- **Comfort**: Head-locked reticle only — zero world rotation or camera zoom.

### `M09` — Potion Brewer (Seated Trunk & Bilateral Arm Stirring)
- **Level**: B | **Category**: `CORE_POSTURE`
- **Cauldron Geometry**: Center `c_c = (0, y_lap + 0.15 m, 0.48 * min(R_f,L, R_f,R))`, stir radius `r_stir = min(0.22 m, 0.65 * min(x_twist,L, x_twist,R))`.
- **Evaluation**: Midpoint `p_mid = 0.5 * (p_L + p_R)` tracks horizontal circle (`|ρ - r_stir| <= 0.09 m`), with hand Clasp distance `||p_L - p_R|| <= 0.28 m`. Completes `360°` per revolution and reverses direction every `2` revolutions.

### `M10` — Laser Evader (Controlled Lateral Trunk Lean)
- **Level**: B | **Category**: `CORE_POSTURE`
- **Wall Sequence**: Always alternates Side (`s ∈ {-1, +1}`) → Center Return (`0.0 m`) → Opposite Side.
- **Target Gap Center**: `g = s * k_lean * Δx_max,dir` (`k_lean = 0.60 / 0.70 / 0.80`), tolerance `r_gap = 0.08 m`.
- **Safety Guard**: Evaluates `|Δx_head| <= min(Δx_max,dir + 0.05 m, 0.30 m)` and drop check `p_head.y - p_head,0.y >= -0.15 m` (prevents ducking/forward bending).

---

## 6. Scoring, Combo Multiplier, & Adaptive Tempo

Implemented in [`core/scoring.gd`](../core/scoring.gd) and [`core/adaptive_tempo.gd`](../core/adaptive_tempo.gd).

### 6.1 Per-Action Scoring Formula
- **Base Hit**: `P_base = 100`
- **Timeliness Bonus (`0..50`)**:
  $$P_{\text{time}} = \text{round}\left(50 \cdot \text{clamp}\left(1 - \frac{t_{\text{hit}} - t_{\text{spawn}}}{T_{\text{window}}}, 0, 1\right)\right)$$
- **Solid Velocity Bonus (`M01` only)**: `P_vel = 25` if `v_punch >= 1.25 m/s` else `0`.
- **Streak Multiplier (`1.0x` to `2.0x` cap)**:
  $$M_{\text{streak}} = 1.0 + \frac{\min(\text{streak}, 20)}{20}$$
- **Total Action Points**:
  $$P_{\text{action}} = \text{round}\big((P_{\text{base}} + P_{\text{time}} + P_{\text{vel}}) \cdot M_{\text{streak}}\big)$$

### 6.2 Adaptive Tempo (`AdaptiveTempo`)
- Evaluates rolling window of last `8` discrete targets:
  - Hit rate `>= 85%` (`>= 7/8`) → `BPM = min(BPM + 5, BPM_max)`
  - Hit rate `< 60%` (`<= 4/8`) → `BPM = max(BPM - 5, BPM_min)`

---

## 7. Safety Monitors

Implemented in [`safety/safety_monitors.gd`](../safety/safety_monitors.gd):
1. **Hands-to-Lap Auto-Pause (`AutoPauseMonitor`)**:
   - Triggers when both hands remain below `y_lap` (`y_L <= y_lap` and `y_R <= y_lap`) with speed `< 0.15 m/s` for `2.5 s` continuously.
   - Immediately freezes active round timers and preserves streak/score.
2. **Excessive Lean Pause (`LeanMonitor`)**:
   - Standard mechanics (`M01`–`M09`): pauses if horizontal head offset `d_lean > 0.25 m` or vertical drop `< -0.20 m` for `0.5 s`.
   - `M10` Laser Evader override: pauses if `|Δx_head| > min(Δx_max,dir + 0.05 m, 0.30 m)` or vertical drop `< -0.15 m`.
3. **Continuous Exercise Rest Reminder (`RestReminderMonitor`)**:
   - Accumulates active exercise time; after `15 minutes` (`900 s`), displays a non-punitive hydration/stretch reminder at the next round boundary.

---

## 8. Local Persistence Schemas (`SaveService`)

Implemented in [`autoload/save_service.gd`](../autoload/save_service.gd):
- **`user://comfort_profile.json`**: Schema `v1` storing `body_origin_world`, `body_forward_world`, `head_neutral_body`, `lap_height_y`, reach values, `obstacle_spheres`, module calibration flags/values, `difficulty_preset`, `no_trunk_mode`, `has_stable_chair`, and `last_session_mechanic_ids`.
- **`user://session_history.json`**: Schema `v1` storing personal bests per mechanic (`M01`..`M10`), `best_score_attack_total`, and up to `50` historical session records (`timestamp_utc`, `mode`, `preset`, `total_score`, `active_duration_s`, and per-round telemetry).
- **Corrupt JSON Recovery**: If either file is unreadable or malformed, `SaveService` renames it with a `.bak` suffix, initializes clean defaults, and routes to first-time Base Calibration without crashing.
