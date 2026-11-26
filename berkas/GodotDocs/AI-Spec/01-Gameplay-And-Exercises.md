# 01 — Gameplay Loop, Scoring, Tempo & 7 Curated Exercises

> **Sources of Truth:** `godot/autoload/game_flow.gd`, `godot/core/session_draw.gd`, `godot/core/difficulty_preset.gd`, `godot/core/scoring.gd`, `godot/core/adaptive_tempo.gd`, `godot/core/mechanics_math.gd`, and `godot/mechanics/*`.

---

## 1. Core Loop & Session Modes (`Hybrid Rhythm-Flow`)

### 1.1 Round Timing Constants (`GameFlowController`)
- `ROUND_INTRO_SECONDS = 3.0` (`ZenoEnums.AppState.ROUND_INTRO` — previews exercise & demonstrates movement via Zeno)
- `SINGLE_EXERCISE_SECONDS = 45.0` (single exercise chosen from `Exercise Library`)
- `QUICK_BREAK_ROUND_SECONDS = 30.0` (per round inside a 5-round `Quick Break` mix = `2.5 min` active play)
- `ROUND_OUTRO_SECONDS = 2.0`
- `RESUME_COUNTDOWN_SECONDS = 3.0` (graceful resume ramp after pause)

### 1.2 Curated Playlist & Category Filters (`SessionDraw`)
`SessionDraw.get_all_exercises()` registers **7 curated exercises** grouped into 3 body-focus categories (`ZenoEnums.ExerciseCategory`):
- **Active:** `BOARD_SMASH` (1), `WIDE_SPLIT` (2)
- **Mobility:** `SKY_REACH` (3), `ORBIT_FLOW` (4), `WRIST_TWIST` (5)
- **Posture (`Level B` safety):** `TORSO_TWIST` (6), `HORIZON_GAZE` (7)

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
- `SOLID_STRIKE_BONUS = 25` (e.g., solid punch in `Board Smash`, dual split completion, golden lantern catch, clean twist)
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

## 3. Summary of the 7 Curated Exercises (`ZenoEnums`)

| ID | Name | Category | Target Area | Safety | Prop / Visual | Primary Kinematics & Anti-Cheat |
| :-: | :--- | :--- | :--- | :---: | :--- | :--- |
| 1 | **Board Smash** | Active | Arms & Chest | Level A | `KarateBoard.glb` | Forward extension `z >= 0.22 m` & velocity `>= 0.25 m/s` (`front`/`hook`/`uppercut`) + segment anti-tunnelling |
| 2 | **Wide Split** | Active | Upper Back & Chest | Level A | Twin `KarateBoard.glb` + center ring | Hands must prime near chest (`span <= 0.36 m`, `z >= 0.15 m`) before opening `20°` scapular plane |
| 3 | **Sky Reach** | Mobility | Shoulders | Level A | Descending mint/gold lanterns | Diagonal shoulder-upward reach with neck-safe gaze elevation clamped `<= 45.0°` |
| 4 | **Orbit Flow** | Mobility | Shoulders & Mobility | Level A | Dual vertical rings + guide sparks | Signed angular circle progress requiring `radius >= max(0.10, 0.55 * r)` (rejects small wrist tremor) |
| 5 | **Wrist Twist** | Mobility | Wrists & Forearms | Level A | Dual glowing dials (`target` + `needle`) | Forearm held within `0.20 m` of anchor + wrist roll within `±14°` for `0.30 s` |
| 6 | **Torso Twist** | Posture | Core & Spine | **Level B** | Side `KarateBoard.glb` + chest guard ring + beam | Hands inside `0.32 m` chest guard AND `|head_yaw - aim_yaw| <= 22.0°` locked for `0.35 s` |
| 7 | **Horizon Gaze** | Posture | Neck | **Level B** | Left/Right horizon lanterns | Smooth head yaw dwell `1.0 s` within `pitch <= 20°` & head speed `<= 60°/s` (fast turns pause dwell) |

---

## 4. Exact Exercise Formulas & Implementation Specs (`MechanicsMath`)

### 4.1 Board Smash (`board_smash/board_smash.gd`)
- **Biomechanics:** Seated boxing patterns (`front` jab/cross, `hook` side punch, `uppercut` upward punch; `GENTLE` uses `front` only). Works pectoral, anterior deltoid, and triceps safely on a non-swivel chair.
- **Formulas (`MechanicsMath.board_smash_params`):**
  - `z_hit = clamp(k, 0.10, 0.85) * reach_forward_m`
  - Approach velocity: `v_a = (z0_m - z_hit) / max(0.05, t_lead_s)` (`z0_m = 1.45 m`, `t_lead_s = 1.0 s`).
- **Strike Validation (`board_smash_is_valid_strike` & `ZenoGeometry.check_valid_hand_hit`):**
  - Anti-tunnelling segment-to-sphere intersection (`hand_tip_radius = 0.04 m`).
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
  - Resolves obstacle avoidance via `ComfortProfile.resolve_obstacle_free_position()`. Every 4th lantern is golden (`+50` bonus).

### 4.4 Orbit Flow (`orbit_flow/orbit_flow.gd`)
- **Biomechanics:** Smooth continuous shoulder circumduction replacing untrackable shrug/roll motion using measurable XR hand positions.
- **Formulas (`MechanicsMath.orbit_flow_evaluate_signed` & `orbit_flow_cadence`):**
  - Circle centers at `(±0.22, 0.04, 0.40)` in chest `BodyFrame`.
  - Computes planar radius in hand plane; rejects wrist tremor where `radius < max(0.10, preset.orbit_radius_m * 0.55)` (`effective_delta_rad = 0`).
  - Uses signed `wrapf(curr_angle - prev_angle, -PI, PI) * dir_sign` so back-and-forth oscillation cancels to `0.0`.
  - Flips clockwise / counter-clockwise every `10.0 s`; completing `TAU` (`2π`) radians awards circle hit + chime SFX.

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
  - **Chest Guard Anti-Cheat:** Both enabled hands must remain within `guard_radius_m = 0.32 m` of chest `(0,0,0)` so player cannot reach sideways with one arm while keeping trunk facing front.
  - **Head-Torso Sync Anti-Cheat:** `abs(head_yaw_deg - aim_yaw_deg) <= 22.0°` and `abs(aim_yaw_deg - target_yaw_deg) <= 9.0°` (`8.0°` math default) held for `0.35 s` shatters the side board (`Level B` never rewards velocity).

### 4.7 Horizon Gaze (`horizon_gaze/horizon_gaze.gd`) — Safety Level B
- **Biomechanics:** Controlled horizontal cervical rotation (`pitch <= 20.0°`) tracking warm horizon lanterns at `2.2 m` distance (`k * neck_deg` clamped `[22.0°, 52.0°]`).
- **Formulas (`MechanicsMath.horizon_gaze_step`):**
  - If `head_angular_speed_deg_s > 60.0°/s`: **pauses dwell without resetting** and shows calm cue `"Turn your head a little slower"` (while clearing `_smooth_all_the_way` bonus flag).
  - If aligned within tolerance (`6.0°` runtime / `5.0°` math default, `pitch <= 20.0°`): increments `dwell_s += dt`; reaching `1.0 s` completes scan (`+15` bonus if smooth throughout).
