# 02 — Coordinate Space, Calibration, Input Lock & Safety

> **Sources of Truth:** `godot/core/spec_space.gd`, `godot/core/body_frame.gd`, `godot/core/comfort_profile.gd`, `godot/calibration/calibration_controller.gd`, `godot/autoload/platform.gd`, `godot/safety/safety_monitors.gd`, `godot/autoload/save_service.gd`, `godot/main.gd`.

---

## 1. Coordinate Spaces (`SpecSpace` ↔ Godot)

All gameplay math is authored in **left-handed** chest-relative **SpecSpace** (`+X` right, `+Y` up, `+Z` forward; clockwise yaw positive from above), then transformed at the **right-handed** Godot scene boundary (`+X` right, `+Y` up, `-Z` forward; counter-clockwise `rotation.y` positive from above) via `SpecSpace`:

| Axis / Angle | SpecSpace (`BodyFrame` local) | Godot World / Local | Conversion (`SpecSpace`) |
| :--- | :--- | :--- | :--- |
| Lateral Right | `+X` | `+X` | `x_godot = x_spec` |
| Up | `+Y` | `+Y` | `y_godot = y_spec` |
| Forward | **`+Z`** | **`-Z`** | `z_godot = -z_spec` (`to_godot`, `to_spec` self-inverse) |
| Positive Yaw | **Clockwise / Turn RIGHT** | Counter-clockwise / Turn LEFT | `yaw_godot = -yaw_spec` (`yaw_deg_to_godot_deg`) |

---

## 2. Stationary `BodyFrame` & Anti-Wobble Rule

- `BodyFrame` defines chest origin `origin_spec` (`Vector3`, default `Vector3(0.0, 0.95, 0.0)`) and horizontal yaw `yaw_spec_rad` (`float`, default `0.0`).
- `BodyFrame.rebuild_from_head_and_offset(head_pos_spec, head_forward_spec, chest_offset)` projects `head_forward_spec` onto the XZ horizontal plane (`y = 0`), extracts horizontal yaw `atan2(flat_fwd.x, flat_fwd.z)`, and sets:
  `origin_spec = head_pos_spec + rotate_local_to_world_spec(chest_offset_from_head_spec)`
  where default `chest_offset_from_head_m = Vector3(0.0, -0.25, 0.08)` (chest sits `25 cm` below head, `8 cm` back along viewer's forward in SpecSpace).
- **Dojo Floor Anchoring (`Main._sync_dojo_floor_transform`):** Anchors `dojo_env_root` and fallback `floor_platform` cleanly at `BodyFrame` local `(0.0, -0.68, 0.0)`.
- **Camera Anti-Wobble Invariant (`Main._sync_xr_camera_body_frame`, `Main._rebuild_body_frame_from_camera`):**
  1. `BodyFrame` is rebuilt **ONLY** on:
     - Boot / initial valid XR camera pose (`_has_initial_xr_pose` first non-zero frame),
     - Explicit `SEAT_ANCHOR` step during `CALIBRATION`,
     - OpenXR `pose_recentered` / user `"Recenter"` action (`_recenter_seated_view`).
  2. Never derive `origin_spec.y` from camera look-vector Y or pitch angle, and never re-anchor `BodyFrame` per frame during gameplay or menu browsing. Thus looking up (`+42°`) or down (`-42°`) keeps the room, UI panels, Zeno, and exercise targets 100% stationary (`distance == 0.0 m` verified in `STATIONARY-BODYFRAME` test).
  3. Never translate, rotate, or scale `XROrigin3D` during gameplay.

---

## 3. 3-Step Seated Calibration (`CalibrationController`)

Designed to complete in **<= 15 seconds**, plus 1-tap `quick_recenter_seat()` from `Welcome` or `Settings`:

1. **Step 1 — `SEAT_ANCHOR` (`Seated Posture`):**
   - Captures neutral upright seated head height (`clamped [0.70, 1.80] m`, default `1.18 m`), rebuilds stationary `BodyFrame`, and records `seat_anchor_local_spec`.
2. **Step 2 — `COMFORT_REACH` (`Left` then `Right`):**
   - Samples extended left/right hand local Spec coordinates (`left/right_reach_forward_m = clamp(max(0.35, local.z), 0.30, 0.85)` -> effective `[0.35, 0.85] m`; `left/right_arm_length_m = clamp(max(0.45, arm_len), 0.35, 0.85)` -> effective `[0.45, 0.85] m` from shoulder offset `(±half_w, 0.12, 0.0)`).
   - Pressing `"Skip Step"` on Left disables `left_enabled`; pressing `"Skip Step"` on Right disables `right_enabled` only if `left_enabled` is still `true` (guaranteeing at least one hand remains enabled) and auto-switches `effective_hand_mode`.
3. **Step 3 — `LAP_ZONE` (`Rest & Lap Zone`):**
   - Samples resting lap midpoint between both hands (clamped below chest `y <= -0.10 m`, fallback `(0.0, -0.45, 0.20)`), marks profile complete, and persists via `SaveService`.

### Comfort Reach Cap & Obstacle Exclusion (`ComfortProfile`)
- `MAX_REACH_FACTOR_K = 0.85`: No target ever spawns beyond `85%` of calibrated comfortable forward reach or arm length.
- `is_violating_obstacle_zone()` & `resolve_obstacle_free_position()` prevent targets from spawning within `exclusion_radius (0.12 m) + target_radius` of calibrated desk/armrest obstacles.

---

## 4. Strict Session Input Lock & Menu Raycast Rule

### 4.1 `Platform.sample_input_pose(hand, ctrl, locked_input_mode)`
- **No Silent Mid-Session Switching:** Player selects `Controllers` (`CONTROLLER = 0`) or `Hand Tracking` (`HAND_TRACKING = 1`) in `Settings` or `Welcome` (`GameFlow.set_input_mode()` locks `active_input_mode` before `ROUND_PLAY`).
- When locked to `HAND_TRACKING` in XR: reads ONLY `XRServer.get_tracker("/user/hand_tracker/left|right")`. Computes palm world transform, wrist roll, pinch (`thumb_tip <-> index_tip <= 0.035 m`), and grasp (`palm <-> middle_tip <= 0.070 m`). If hand tracking drops, returns `tracked = false` without falling back to `XRController3D`. When `is_xr_active == false` (Desktop Simulator), returns `source = "hand_tracking_sim"` using the virtual controller position.
- When locked to `CONTROLLER` in XR: reads ONLY `XRController3D` pose, `trigger` (`> 0.60`), `grasp` (`grip > 0.50 or trigger > 0.60 or not is_xr_active`), and `rotation_degrees.z` roll.
- During `ROUND_PLAY`, if enabled inputs report `tracked = false` continuously for `>= 2.5 s` (`_input_lost_timer_s` in `main.gd`), the session cleanly pauses with `PauseReason.INPUT_LOST` and prompts the player to restore tracking or switch input safely outside active play.

### 4.2 Zero Raycasting During Gameplay
- `Main.is_ui_raycast_enabled()` returns `GameFlow.current_state != ZenoEnums.AppState.ROUND_PLAY`.
- Menu laser meshes (`left_menu_ray`, `right_menu_ray`) and `ZenoWorldUI._pointer_dot` are hidden throughout `ROUND_PLAY`, enforcing genuine 3D spatial contact.

---

## 5. Safety Monitors (`SafetyMonitors`)

1. **`AutoPauseMonitor` (`lap_distance_threshold_m = 0.15 m`, `hold_duration_seconds = 2.0 s`):**
   - Triggers `PauseReason.AUTO_PAUSE_LAP` (`"Hands rested in lap for 2 seconds. Take a breather!"`) when all enabled hands rest within `0.15 m` of `lap_point_from_chest_m` continuously for `2.0 s`, OR when tracking drops after the hand was last seen in the lower zone (`y <= -0.15 m` below chest — solves Quest/PICO downward FoV tracking loss on knees).
   - `GameFlow.pause_session()` automatically activates real-world Passthrough (`Platform.set_passthrough(true)`) on `AUTO_PAUSE_LAP` when supported by headset blend modes, and turns it back off (`Platform.set_passthrough(false)`) on resume, finish, or return to main menu.
2. **`LeanMonitor` (`lean_threshold_m = 0.22 m`, `hold_seconds = 0.50 s`):**
   - Whenever `abs(head_local_x - seat_anchor_local_x) > 0.22 m` continuously for `0.50 s` during `ROUND_PLAY`, resets the monitor and pauses the session with `PauseReason.LEAN_WARNING` (`"Please return to a centered, upright seated posture."`). (`EventBus.safety_cue` is used for non-pausing in-round guidance such as `HorizonGazeMechanic`'s `"Turn your head a little slower"`.)
3. **`RestReminderMonitor` (`7.0–10.0 min`, default `8.0 min`):**
   - Triggers a restorative break prompt (`PauseReason.REST_REMINDER`, `"Time for a quick breather — relax your shoulders and neck."`). (Real-world Passthrough toggling in `GameFlow.pause_session()` is currently bound specifically to `AUTO_PAUSE_LAP`.)

---

## 6. Local JSON Persistence (`SaveServiceClass`)

- Stores 4 JSON files under `user://` (with automatic fallback to `/tmp/zenofit_userdata/` in headless/sandbox environments):
  - `calibration_profile.json`
  - `settings.json` (`difficulty`, `hand_mode`, `input_mode`, `haptics_enabled`, `haptic_intensity`, `audio_volume`, `rest_reminder_minutes`, `hud_distance_m`, `hud_scale`)
  - `sessions.json` (rolling up to `30` sessions storing `dateUtc`, `mode`, `inputMode`, `difficulty`, `durationSeconds`, `hits`, `misses`, `accuracyPercent`, `score`, `rank`, `isNewPersonalBest`)
  - `personal_best.json` (`overall_best_score`, `overall_best_rank`, per-mode/exercise `records` keyed by `"quick_break"` or `"ex_<id>"`, plus `get_weekly_stats()`)
- Includes `delete_all_saved_data()` accessible directly from Settings.
