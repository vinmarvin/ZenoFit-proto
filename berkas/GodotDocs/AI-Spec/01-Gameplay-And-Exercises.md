# 01 — Gameplay Loop, Scoring, Tempo & 11 Curated Exercises

> **Sources of Truth:** `godot/autoload/game_flow.gd`, `godot/core/enums.gd`, `godot/core/session_draw.gd`, `godot/core/difficulty_preset.gd`, `godot/core/scoring.gd`, `godot/core/adaptive_tempo.gd`, `godot/core/mechanics_math.gd`, `godot/main.gd`, and `godot/mechanics/*`.

---

## 1. Core Loop & Session Modes (`Hybrid Rhythm-Flow`)

### 1.1 Round Timing Constants (`GameFlowController`)
- `ROUND_INTRO_SECONDS = 3.0` (`ZenoEnums.AppState.ROUND_INTRO` — previews exercise & demonstrates movement via Zeno)
- `SINGLE_EXERCISE_SECONDS = 45.0` (single timed exercise chosen from `Exercise Library`)
- `QUICK_BREAK_ROUND_SECONDS = 30.0` (per timed round inside a 5-round `Quick Break` mix)
- `ROUND_OUTRO_SECONDS = 2.0`
- `RESUME_COUNTDOWN_SECONDS = 3.0` (graceful resume ramp after pause)
- **Explicit Two-Set Round Completion (`require_explicit_round_completion`):** Set `true` in `Main._on_round_started()` whenever `active_mechanic.has_two_set_completion()` is `true` (`SHOULDER_PRESS`, `BICEP_CURL`, `ARM_CIRCLES`, `LATERAL_RAISE`). During `ROUND_PLAY`, `round_timer_s` clamps at `0.0` instead of ending the round on timeout; the round ends via `GameFlow.complete_active_round()` once `active_mechanic.is_exercise_completed()` becomes `true` (after both Set 1 and Set 2 reach `12` reps).

### 1.2 Curated Playlist & Category Filters (`SessionDraw`)
`SessionDraw.get_all_exercises()` registers **11 curated exercises** grouped into 3 body-focus categories (`ZenoEnums.ExerciseCategory`):
- **Active (5):** `BOARD_SMASH` (1), `WIDE_SPLIT` (2), `SHOULDER_PRESS` (8), `BICEP_CURL` (9), `LATERAL_RAISE` (11)
- **Mobility (4):** `SKY_REACH` (3), `ORBIT_FLOW` (4), `WRIST_TWIST` (5), `ARM_CIRCLES` (10)
- **Posture (`Level B` safety, 2):** `TORSO_TWIST` (6), `HORIZON_GAZE` (7)

`SessionDraw.draw_quick_break_mix(previous_lineup, rng)` guarantees:
1. Exactly **5 distinct exercises** with at least 1 exercise from each category (`ACTIVE`, `MOBILITY`, `POSTURE`).
2. Down-weights exercises present in `previous_lineup` (`0.5` vs `1.0`).
3. Caps `Level B` (`TORSO_TWIST`, `HORIZON_GAZE`) at `<= 2` rounds and arranges the sequence via `_arrange_without_consecutive_level_b()` so two `Level B` rounds NEVER appear back-to-back.

---

## 2. Difficulty Presets, Scoring & Adaptive Tempo

### 2.1 Difficulty Tiers (`DifficultyPreset`)
All presets enforce `reach_factor_k <= ComfortProfile.MAX_REACH_FACTOR_K (0.85)`:

| Constant / Tunable | Gentle (`gentle.tres`) | Standard (`standard.tres`) | Active (`active.tres`) |
| :--- | :---: | :---: | :---: |
| `reach_factor_k` | `0.60` | `0.75` | `0.85` |
| `target_radius_m` | `0.12` | `0.10` | `0.085` |
| `start_tempo_bpm` | `50.0` | `60.0` | `70.0` |
| `max_tempo_bpm` | `70.0` | `80.0` | `90.0` |
| `target_lifetime_beats` | `3` | `2` | `2` |
| `reach_elevation_phi_deg` | `35.0` | `45.0` | `52.0` |
| `orbit_radius_m` | `0.14` | `0.18` | `0.22` |
| `orbit_cadence_hz` | `0.55` | `0.75` | `0.90` |
| `wrist_target_deg` | `45.0` | `55.0` | `65.0` |

### 2.2 Scoring & Ranks (`ZenoScoring`)
- `BASE_HIT_POINTS = 100`
- `MAX_TIMELINESS_BONUS = 50`: `timeliness = clampf(1.0 - t_hit_s / lifetime_s, 0.0, 1.0)`, `speed_bonus = floor(50 * timeliness)`
- `SOLID_STRIKE_BONUS = 25` (e.g., solid punch in `Board Smash`, dual split completion, golden lantern catch, high-tension two-set rep)
- `TwoSetTensionMechanic` Bonus: reps achieving tension quality ratio `>= 0.65` earn `is_solid = true` (`+25` solid bonus) plus `extra_bonus = +35` (`lifetime_s = 3.0 s`).
- `OrbitFlowMechanic` Direct Scoring: awards `130` base points when cadence stays within `±30%` runtime band (or `100` otherwise) via `record_direct_points()`.
- **Hand-Tracking Radius Tolerance (`MechanicBase.get_effective_hit_radius`):** Adds `+0.025 m` to `base_radius_m` whenever `active_input_mode == ZenoEnums.InputMode.HAND_TRACKING`.
- `DEFAULT_COMBO_CAP = 20`: multiplier `1.0 + min(streak_before, 20) / 20.0` (`1.0x .. 2.0x`, e.g., streak `10` = `1.5x`). Total points per hit = `floor(base_points * multiplier)`.
- **Accuracy Rank (`ZenoScoring.compute_rank`):**
  - `>= 90.0%` -> **`S+`**
  - `>= 75.0%` -> **`S`**
  - `>= 55.0%` -> **`A`**
  - `>= 35.0%` -> **`B`**
  - `< 35.0%` -> **`C`**

### 2.3 Adaptive Tempo (`AdaptiveTempo`)
- Evaluates rolling window of `DEFAULT_WINDOW_SIZE = 8` target outcomes:
  - Accuracy `>= 0.85` -> `current_bpm = min(max_bpm, current_bpm + 5.0)`
  - Accuracy `< 0.60` -> `current_bpm = max(40.0, current_bpm - 5.0)`
  - Beat interval: `60.0 / current_bpm` s.

---

## 3. Summary of the 11 Curated Exercises (`ZenoEnums`)

| ID | Name | Category | Target Area | Safety | Mode / Sets | Prop / Visual | Primary Kinematics & Anti-Cheat |
| :-: | :--- | :--- | :--- | :---: | :--- | :--- | :--- |
| 1 | **Board Smash** | Active | Arms & Chest | Level A | Timed (`30s` / `45s`) | `KarateBoard.glb` | Forward extension `z >= 0.22 m` & velocity `>= 0.25 m/s` (`front`/`hook`/`uppercut`) + segment anti-tunnelling |
| 2 | **Wide Split** | Active | Upper Back & Chest | Level A | Timed (`30s` / `45s`) | Twin `KarateBoard.glb` + center ring | Hands must prime near chest (`span <= 0.36 m`, `z >= 0.15 m`) before opening `20°` scapular plane |
| 3 | **Sky Reach** | Mobility | Shoulders | Level A | Timed (`30s` / `45s`) | Descending mint/gold lanterns | Diagonal shoulder-upward reach with neck-safe gaze elevation clamped `<= 45.0°` |
| 4 | **Orbit Flow** | Mobility | Shoulders & Mobility | Level A | Timed (`30s` / `45s`) | Dual vertical rings + guide sparks | Signed angular circle progress requiring `radius >= max(0.10, 0.55 * r)` (rejects small wrist tremor) |
| 5 | **Wrist Twist** | Mobility | Wrists & Forearms | Level A | Timed (`30s` / `45s`) | Dual glowing dials (`target` + `needle`) | Forearm held within `0.20 m` of anchor + wrist roll within `±14°` for `0.30 s` |
| 6 | **Torso Twist** | Posture | Core & Spine | **Level B** | Timed (`30s` / `45s`) | Side `KarateBoard.glb` + chest guard ring + beam | Hands inside `0.32 m` chest guard AND `|head_yaw - aim_yaw| <= 22.0°` locked for `0.35 s` |
| 7 | **Horizon Gaze** | Posture | Neck | **Level B** | Timed (`30s` / `45s`) | Left/Right horizon lanterns | Smooth head yaw dwell `1.0 s` within `pitch <= 20°` & head speed `<= 60°/s` (fast turns pause dwell) |
| 8 | **Shoulder Press** | Active | Shoulders & Triceps | Level A | Two-Set (`2 × 12` reps) | Vertical tension line + `Box` targets (`0.11 m`) | Upward -> Downward along calibrated vertical corridor (`tol = 0.12 m`); optional dumbbell note |
| 9 | **Bicep Curl** | Active | Biceps | Level A | Two-Set (`2 × 12` reps) | Curved tension arc + `Orb` targets (`r = 0.062 m`) | Elbow Flexion -> Elbow Extension along 5-point arc (`tol = 0.12 m`); optional dumbbell note |
| 10 | **Arm Circles** | Mobility | Shoulders | Level A | Two-Set (`2 × 12` reps) | Dual side-plane (`Y-Z`) tension rings + 4 checkpoint orbs (`r = 0.055 m`) | Clockwise -> Counterclockwise with signed-direction check; optional dumbbell note |
| 11 | **Lateral Raise** | Active | Lateral Deltoid | Level A | Two-Set (`2 × 12` reps) | Lateral arc tension path + `Box` targets (`0.11 m`) | Raising -> Lowering along quarter-sine lateral arc (`tol = 0.12 m`); no dumbbell note |

---

## 4. Exact Exercise Formulas & Implementation Specs (`MechanicsMath` & `MechanicalTensionGuide`)

### 4.1 Board Smash (`board_smash/board_smash.gd`)
- **Biomechanics:** Seated boxing patterns (`front` jab/cross, `hook` side punch, `uppercut` upward punch; `GENTLE` uses `front` only). Works pectoral, anterior deltoid, and triceps safely on a non-swivel chair.
- **Formulas (`MechanicsMath.board_smash_params`):**
  - `z_hit = clamp(k, 0.10, 0.85) * reach_forward_m`
  - Approach velocity: `v_a = (z0_m - z_hit) / max(0.05, t_lead_s)` (`z0_m = 1.45 m`, `t_lead_s = 1.0 s`; `HIT_THRESHOLD_Z_MIN = 0.18 m`).
- **Strike Validation (`board_smash_is_valid_strike` & `ZenoGeometry.check_valid_hand_hit`):**
  - Hit radius `get_effective_hit_radius(max(0.13, preset.target_radius_m + 0.03))` with anti-tunnelling segment-to-sphere intersection (`hand_tip_radius = 0.04 m`).
  - Anti-cheat: rejects chest-close wrist flicks (`curr_local.z < 0.22 m`) and stationary hands (`speed < 0.25 m/s`); for `uppercut` requires `curr_local.y >= 0.02 m`.
  - `board_smash_is_solid_hit`: `speed >= 0.45 m/s` awards `SOLID_STRIKE_BONUS (+25)` and strong haptic pulse.
- **Fracture Feedback:** Calls `KarateBoardProp.trigger_break()` + spatial `wood_crack` SFX (`Platform.play_sfx("wood_crack", streak)`).

### 4.2 Wide Split (`wide_split/wide_split.gd`)
- **Biomechanics:** Dual-arm horizontal abduction / chest opener (anti-slouching) set in the joint-safe `20°` scapular plane.
- **Target Placement (`MechanicsMath.wide_split_compute_targets`):**
  - `r = clamp(k, 0.10, 0.85) * arm_length_m`
  - `half_w = clamp(shoulder_width_m * 0.5, 0.14, 0.28)`
  - `x_mag = half_w + r * cos(20°) * 0.65`, `z_pos = max(0.28, r * sin(20°) + 0.20)`
  - Left board `(-x_mag, 0.06, z_pos)` rotated `+72°`; Right board `(+x_mag, 0.06, z_pos)` rotated `-72°`.
- **Two-Stage Anti-Cheat (`wide_split_evaluate`):**
  - `in_center` primes when `span <= chest_prime_gap_m` (`0.36 m` runtime) and both hands are forward (`z >= 0.15 m`).
  - `split_complete` fires only after priming when `span >= target_span * 0.86` (supports single-hand mode too). Both `KarateBoardProp` shatter simultaneously.

### 4.3 Sky Reach (`sky_reach/sky_reach.gd`)
- **Biomechanics:** Alternating diagonal upward shoulder elevation opening anterior shoulder capsule without cervical hyperextension.
- **Formulas (`MechanicsMath.sky_reach_placement`):**
  - Starts from shoulder anchor `(±half_w, 0.12, 0.0)` and `r = k * arm_length_m`.
  - Computes `y = shoulder.y + r * sin(phi)`, `z = shoulder.z + r * cos(phi)`.
  - Decrements `phi` in `1.0°` steps down to `5.0°` until `atan2(y - y_eye_m, max(0.01, z)) <= 45.0°` (`y_eye_m = 0.25 m`).
  - Resolves obstacle avoidance via `ComfortProfile.resolve_obstacle_free_position()`. Lantern spawns `+0.24 m` above catch height, descends at `0.34 m/s`, and misses below `-0.26 m`; every 4th lantern is golden (`is_solid = true`, `extra_bonus = +50`).

### 4.4 Orbit Flow (`orbit_flow/orbit_flow.gd`)
- **Biomechanics:** Smooth continuous shoulder circumduction replacing untrackable shrug/roll motion using measurable XR hand positions.
- **Formulas (`MechanicsMath.orbit_flow_evaluate_signed` & `orbit_flow_cadence`):**
  - Circle centers at `(±0.22, 0.04, 0.40)` in chest `BodyFrame`; runtime evaluates planar radius and angle in the **XY plane** (`Vector2(hand_spec.x, hand_spec.y)`).
  - Computes planar radius in hand plane; rejects wrist tremor where `radius < max(0.10, preset.orbit_radius_m * 0.55)` (`effective_delta_rad = 0`).
  - Uses signed `wrapf(curr_angle - prev_angle, -PI, PI) * dir_sign` so back-and-forth oscillation cancels to `0.0`.
  - Flips clockwise / counter-clockwise every `10.0 s`; completing `TAU` (`2π`) radians evaluates cadence against `0.30` runtime tolerance (`0.25` math default), awarding `130` (in-band) or `100` (out-of-band) direct base points + chime SFX.

### 4.5 Wrist Twist (`wrist_twist/wrist_twist.gd`)
- **Biomechanics:** Pronation / supination forearm mobility to relieve repetitive desk mouse/keyboard strain (*anti-RSI*).
- **Formulas (`MechanicsMath.wrist_twist_evaluate`):**
  - Dual glowing dial props anchored at `(±0.22, -0.02, 0.42)`.
  - Forearm must stay within `anchor_radius_m = 0.20 m` of dial center (`in_zone`), preventing elbow/shoulder swinging cheat.
  - Angular error `abs(wrapf(roll_deg - target_deg, -180, 180)) <= 14.0°` held for `0.30 s` scores hit and flips target sign (`±preset.wrist_target_deg`).

### 4.6 Torso Twist (`torso_twist/torso_twist.gd`) — Safety Level B
- **Biomechanics:** Gentle seated thoracic spine rotation left/right toward side `KarateBoard.glb` targets, strictly calibrated for non-swivel chairs.
- **Formulas (`MechanicsMath.torso_twist_target` & `torso_twist_evaluate`):**
  - Target yaw: `psi_mag_deg = min(k * max_side_deg, 55.0)` at radial distance `d = 1.20 m` (`1.25 m` math default).
  - **Chest Guard Anti-Cheat:** Both enabled hands must remain within `guard_radius_m = 0.32 m` of chest `(0,0,0)` (visualized by chest guard ring at `(0.0, 0.0, 0.22)` and `1.15 m` aim beam) so player cannot reach sideways with one arm while keeping trunk facing front.
  - **Head-Torso Sync Anti-Cheat:** `abs(head_yaw_deg - aim_yaw_deg) <= 22.0°` and `abs(aim_yaw_deg - target_yaw_deg) <= 9.0°` (`8.0°` math default) held for `0.35 s` shatters the side board (`Level B` never rewards velocity).

### 4.7 Horizon Gaze (`horizon_gaze/horizon_gaze.gd`) — Safety Level B
- **Biomechanics:** Controlled horizontal cervical rotation (`pitch <= 20.0°`) tracking warm horizon lanterns at `y = 0.16 m`, `d = 2.2 m` (`k * neck_deg` clamped `[22.0°, 52.0°]`).
- **Formulas (`MechanicsMath.horizon_gaze_step`):**
  - If `head_angular_speed_deg_s > 60.0°/s`: **pauses dwell without resetting** and shows calm cue `"Turn your head a little slower"` (while clearing `_smooth_all_the_way` bonus flag).
  - If aligned within tolerance (`6.0°` runtime / `5.0°` math default, `pitch <= 20.0°`): increments `dwell_s += dt`; reaching `1.0 s` completes scan (`is_solid = _smooth_all_the_way` + `+15` bonus if smooth throughout).

### 4.8 Shared Two-Set Mechanical Tension Framework (`MechanicalTensionGuide`, `TwoSetTensionMechanic`, `DirectionalTwoSetMechanic`)
- **Two-Set Progression (`TwoSetTensionMechanic`):**
  - `REPS_PER_SET = 12` per set (`Set 1` -> `SET_TRANSITION_SECONDS = 1.6 s` calm transition -> `Set 2` -> completion).
  - Evaluates per-frame corridor adherence (`TENSION_BASE_TOLERANCE_M = 0.12 m`, expanded `+0.025 m` in Hand Tracking via `get_effective_hit_radius`). Reps with tension quality ratio `>= 0.65` earn `is_solid = true` (`+25` solid bonus) and `extra_bonus = +35` (`lifetime_s = 3.0 s`).
- **Continuous Tension Guide (`MechanicalTensionGuide`):**
  - **Polyline (`setup_polyline`):** Subdivides waypoints into a `24`-step Catmull-Rom curve (`0.0025 m` tube radius, `0.007 m` end caps, `0.011 m` flow bead) and evaluates shortest point-to-segment distance `best_dist <= tolerance_m`.
  - **Circle (`setup_circle`):** Renders a thin torus (`0.003 m` tube radius) on `"xy"` or `"yz"` plane and evaluates `sqrt((radial - r)^2 + plane_err^2) <= tolerance_m`.
  - **Unified Tempo Cycle (`use_tempo_cycle = true`, polyline):** `TEMPO_UP_S = 1.0 s` (`"Lift (1s)"`) -> `TEMPO_HOLD_S = 0.6 s` (`"Contract!"`, bead scales `1.28 + 0.12 * sin(10.0 * t)`) -> `TEMPO_DOWN_S = 2.0 s` (`"Lower slowly (2s)"`), `TEMPO_CYCLE_S = 3.6 s`. Visual colors: `COL_GOOD (0.18, 0.84, 1.0)` in-zone, `COL_IDLE (0.28, 0.72, 0.96)` inactive, pulsing `COL_WARN (1.0, 0.36, 0.28)` out-of-zone.
- **Directional Two-Set Flow (`DirectionalTwoSetMechanic`):**
  - Set 1 traverses `waypoints[0] -> waypoints[-1]`; Set 2 reverses `waypoints[-1] -> waypoints[0]`.
  - Requires priming start ring (`prime_r = get_effective_hit_radius(0.11)`, ring radius `0.085 m`) before end target (`0.11 m` Box or `0.062 m` Orb) becomes visible and accepts `segment_hit` (`hit_r = get_effective_hit_radius(preset.target_radius_m + 0.025)`).
- **Optional Dumbbell Guidance (`ZenoEnums.get_exercise_dumbbell_note`):** Shown on `Exercise Preview` strictly for `SHOULDER_PRESS`, `BICEP_CURL`, and `ARM_CIRCLES`; returns `""` for `LATERAL_RAISE` and exercises `1..7`.
- **Shared Gameplay VFX:** `MechanicBase.spawn_hit_vfx()` (shockwave rings + 10 crystal shards), `spawn_prime_vfx()` (lock-on pulse ring), `spawn_celebration_vfx()` (golden/sakura burst on Set 1 / Set 2 completion), paired with `Main` hand motion trails (`speed >= 0.35 m/s`) and floating `Label3D` score popups.

### 4.9 Shoulder Press (`shoulder_press/shoulder_press.gd`)
- **Biomechanics:** Overhead vertical press (`Set 1: Upward Movement`, `Set 2: Downward Movement`) using `Box` targets (`0.11 m`).
- **Calibrated Waypoints:** `k = clamp(preset.reach_factor_k, 0.35, 0.85)`, `z = 0.28 m` (`clamp(0.28, 0.22, 0.36)`), `y_low = clamp(shoulder.y + 0.02, -0.02, 0.16)`, `y_high = clamp(shoulder.y + arm_len * k * 0.62, y_low + 0.20, 0.48)`, across 3 waypoints tapering slightly inward (`shoulder.x ± 0.04 -> ±0.03 -> ±0.02`).

### 4.10 Bicep Curl (`bicep_curl/bicep_curl.gd`)
- **Biomechanics:** Seated elbow curl (`Set 1: Elbow Flexion`, `Set 2: Elbow Extension`) using `Orb` targets (`r = 0.062 m`).
- **Calibrated Waypoints:** `k = clamp(preset.reach_factor_k, 0.35, 0.85)`, 5-point arc per arm (`t = 0.0 .. 1.0`): `x = shoulder.x ± 0.02`, `y_bot = clamp(shoulder.y - arm_len * k * 0.42, -0.30, -0.06)`, `y_top = clamp(shoulder.y + 0.04, 0.04, 0.22)`, `z = lerp(0.26, 0.36, sin(t * PI))`.

### 4.11 Arm Circles (`arm_circles/arm_circles.gd`)
- **Biomechanics:** Extended lateral shoulder circles in the side `Y-Z` plane (`Set 1: Clockwise`, `Set 2: Counterclockwise`).
- **Ring & Anti-Cheat Specs:** `k = clamp(preset.reach_factor_k, 0.35, 0.85)`, `side_offset = clamp(min_arm_len * k * 0.48, 0.26, 0.36)`, ring centers at `(shoulder.x ± side_offset, clamp(shoulder.y, 0.0, 0.16), 0.26)`, `radius = clamp(min_arm_len * k * 0.30, 0.14, 0.20)` on `"yz"` plane. Uses `CHECKPOINTS_PER_CIRCLE = 4` sequential orbs (`r = 0.055 m`, `hit_r = get_effective_hit_radius(preset.target_radius_m + 0.03)`), `dir_sign = -1.0` (Set 1) / `+1.0` (Set 2), and validates direction via `MechanicsMath.orbit_flow_evaluate_signed(..., radius * 0.45)` (flags wrong direction when `signed_delta_rad < -0.06`).

### 4.12 Lateral Raise (`lateral_raise/lateral_raise.gd`)
- **Biomechanics:** Seated lateral deltoid abduction (`Set 1: Raising Movement`, `Set 2: Lowering Movement`) using `Box` targets (`0.11 m`); no dumbbell note.
- **Calibrated Waypoints:** `k = clamp(preset.reach_factor_k, 0.35, 0.85)`, 5-point quarter-sine lateral arc per arm (`t = 0.0 .. 1.0`): `x_low = shoulder.x ± 0.04`, `x_high = shoulder.x ± clamp(arm_len * k * 0.62, 0.24, 0.44)`, `y_low = clamp(shoulder.y - arm_len * k * 0.40, -0.30, -0.06)`, `y_high = clamp(shoulder.y + 0.02, 0.02, 0.20)`, `z = 0.24`, `x = lerp(x_low, x_high, sin(t * PI * 0.5))`, `y = lerp(y_low, y_high, t)`.
