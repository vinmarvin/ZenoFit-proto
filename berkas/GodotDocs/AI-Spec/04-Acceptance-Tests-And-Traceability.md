# 04 — Automated Acceptance Tests & Traceability Matrix

> **Sources of Truth:** [`godot/tests/run_acceptance_tests.gd`](../../../godot/tests/run_acceptance_tests.gd) and [`godot/tests/test_acceptance_suite.gd`](../../../godot/tests/test_acceptance_suite.gd).

---

## 1. Execution Command

On fresh checkouts or after pulling new `class_name` scripts, refresh the local Godot class cache before running headless tests:

```bash
godot --headless --xr-mode off --path /home/ramirez/XR-FP/godot --import
```

Run headless without OpenXR hardware before committing any change to `godot/`:

```bash
godot --headless --xr-mode off --path /home/ramirez/XR-FP/godot -s res://tests/run_acceptance_tests.gd
```

Expected exit code: **`0`**, summary **`TOTAL PASSED: 101 | TOTAL FAILED: 0`**, with zero GDScript compile errors and zero leaked `ObjectDB` instances.

To verify `main.tscn` and all autoload singletons boot cleanly in Desktop Simulator mode:

```bash
godot --headless --xr-mode off --path /home/ramirez/XR-FP/godot --quit-after 2
```

---

## 2. Acceptance Suite Breakdown (`101` Assertions across `16` Test Groups)

| Test Function (`ZenoAcceptanceSuite`) | Test ID(s) | Assertions | What It Verifies |
| :--- | :--- | :---: | :--- |
| `test_spec_space_and_stationary_body_frame` | `SPEC-SPACE`, `STATIONARY-BODYFRAME` | 4 | `+Z` forward -> Godot `-Z`, `+40°` yaw -> Godot `-40°`; pitching XR camera `+42°` / `-42°` leaves `BodyFrame.origin_spec` completely invariant (`0.0000 ± 0.0010 m`) |
| `test_assets_and_karate_board_fracture` | `ASSETS-BOARD`, `ASSETS-ENV`, `ASSETS-ENV-SHADOWS` | 6 | `KarateBoard.glb` loads intact mesh + 2 halves + 6 splinters, starts intact, `trigger_break()` hides intact and plays `Break`; `Environment.glb` keeps 6 room groups & strips 28 stray nodes (`pCube36 == null`); all `192` `Environment.glb` room meshes have shadow casting OFF |
| `test_mascot_fov_and_seven_demos` | `MASCOT-FOV`, `MASCOT-HQ`, `MASCOT-DEMOS`, `MASCOT-SHADOWS` | 15 | `compute_fov_safe_anchor()` stays `<= 24°` across 4 states × 3 HUD distances (`1.30`, `1.65`, `2.20`); textured `Zeno_WithTexture.glb` loads with `EyeHappy_L`; Zeno loops through and animates all 11 exercises from `SessionDraw.get_all_exercises()` + reacts to high-five poke; all Zeno meshes have shadows OFF |
| `test_input_lock_and_safety_monitors` | `INPUT-LOCK`, `SAFETY-LAP`, `SAFETY-LEAN` | 5 | `HAND_TRACKING` lock does NOT silently fall back to controller; `CONTROLLER` lock reads strictly from `XRController3D`; `AutoPauseMonitor` triggers on `2.0 s` lower-zone tracking loss; `LeanMonitor` keeps `0.15 m` safe and warns on `0.26 m` for `0.6 s` |
| `test_ex01_board_smash` | `EX-01` | 5 | `z_hit = 0.75 * 0.60 = 0.45 m`; close-to-chest wrist flick rejected; stationary hand rejected; extended forward punch accepted; `segment_hit` anti-tunnelling passes |
| `test_ex02_wide_split` | `EX-02` | 3 | Twin boards placed forward in `20°` scapular plane; unprimed wide hands rejected; priming at chest (`span <= 0.34 m`) then opening wide succeeds |
| `test_ex03_sky_reach` | `EX-03` | 2 | Diagonal height `0.481 m`; gaze elevation strictly clamped `<= 45.0°` |
| `test_ex04_orbit_flow` | `EX-04` | 2 | Small wrist tremor (`r = 0.05 < 0.12 m`) yields `0` progress; forward + backward oscillation cancels to `0.0` |
| `test_ex05_wrist_twist` | `EX-05` | 2 | Forearm outside `0.20 m` anchor rejected; steady forearm + roll within `±14°` succeeds |
| `test_ex06_torso_twist` | `EX-06` | 4 | Target yaw `= 42.5°`; out-of-guard arm swinging rejected; desynced head (`0°` vs `42.5°`) fails sync check; aligned chest guard + head/torso rotation locks board |
| `test_ex07_horizon_gaze` | `EX-07` | 3 | Fast head turn (`90°/s > 60°/s`) pauses `dwell_s = 0.50 s` without resetting and raises `show_slower_cue`; smooth turn (`25°/s`) completes `1.0 s` dwell |
| `test_live_instantiation_all_seven_exercises` | `LIVE-EXERCISES` | 1 | Instantiates all 7 original timed `MechanicBase` subclasses cleanly, calls `setup()`, `update_mechanic()`, `simulate_auto_action()`, and `clear_arena()` |
| `test_new_upper_body_exercises_and_mechanical_tension` | `NEW-EX-LIST`, `DUMBBELL-NOTE`, `TENSION-POLY`, `TENSION-CIRCLE`, `TENSION-CIRCLE-YZ`, `TENSION-TEMPO`, `TWO-SET` | 26 | Verifies all 11 exercises in `SessionDraw` (1); exact Indonesian dumbbell note strictly on `Shoulder Press`, `Bicep Curl`, and `Arm Circles` and absent on `Lateral Raise` / existing exercises (5); `MechanicalTensionGuide` polyline, XY circle, YZ side-plane circle, and `1s up -> Contract! -> 2s down` tempo labels (4); full 2-set progression (`Set 1 -> 12 reps -> transition -> Set 2 -> 12 reps -> complete`) across all 4 `TwoSetTensionMechanic` subclasses (16) |
| `test_scoring_tempo_and_session_draw` | `TEMPO`, `SCORING`, `QUICK-BREAK` | 3 | `AdaptiveTempo` bumps `60 -> 65 BPM` at `7/8 (87.5%)`; `ZenoScoring` streak `10` applies `1.5x` multiplier (`137 -> 205 pts`); `draw_quick_break_mix` produces 5 exercises covering `Active/Mobility/Posture` with non-consecutive `Level B` |
| `test_calibration_and_persistence` | `CAL-3STEP`, `SAVE-SVC` | 4 | 3-step `CalibrationController` progression (`1/3 -> COMFORT_REACH -> LAP_ZONE -> COMPLETE`); `SaveServiceClass` saves & reloads calibration, personal best, and `get_weekly_stats()` cleanly |
| `test_ui_flow_hud_ergonomics_and_no_debug_strings` | `FLOW-UI`, `HUD-ERGONOMICS`, `PANEL-RESIZE`, `NO-DEBUG-UI`, `CREDITS-ITS` | 16 | Full 11-screen flow (`BOOT -> WELCOME -> MAIN_MENU -> EXERCISE_SELECT -> EXERCISE_PREVIEW -> ROUND_PLAY -> PAUSED -> RESULTS`); `adjust_hud_distance` clamps `[1.30, 2.20]` & resets to `1.65`; `adjust_hud_scale` clamps `[0.85, 1.20]` & resets to `1.00`; panel resize transitions across all 12 built states & all 4 Settings tabs fit without viewport overflow or clipping; zero forbidden debug strings (`M01..M10`, `[Tab]`, `[Space]`, `Politeknik`, `Fruit Harvester`, `Makiwara`) across all 12 built states + exercise copy; Credits contains `Institut Teknologi Sepuluh Nopember` and `jrevel` |
| **Total** | | **101** | **All passing (`TOTAL FAILED: 0`)** |
