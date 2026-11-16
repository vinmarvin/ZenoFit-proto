# ZenoFit (Godot 4.x) — Acceptance Tests & Unity-to-Godot Parity Matrix

This document maps every requirement in [`16-acceptance-tests.md`](../MarkdownGuideForAIReconstruction/16-acceptance-tests.md) and [`03-godot-build.md`](../MarkdownGuideForAIReconstruction/03-godot-build.md) to its concrete implementation and automated verification test in [`tests/test_acceptance_suite.gd`](../tests/test_acceptance_suite.gd).

---

## 1. Automated Acceptance Test Matrix (`AT-01`..`AT-28`)

All tests below run headlessly via:
```bash
/usr/bin/godot --headless --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1 -s res://tests/run_acceptance_tests.gd
```

| Test ID | Specification Requirement | Implementation File(s) | Automated Verification Status |
| :--- | :--- | :--- | :--- |
| **SPEC-SPACE** | Left-handed Spec (`+Z` forward, `+ψ` right) ↔ Right-handed Godot (`-Z` forward, `+rotation.y` left) | [`core/spec_space.gd`](../core/spec_space.gd), [`core/body_frame.gd`](../core/body_frame.gd) | **PASS** (`_test_spec_space_and_body_frame`) |
| **AT-01** | First-Time 7-Step Base Calibration saves valid `comfort_profile.json` and unlocks Score Attack & Practice | [`calibration/calibration_controller.gd`](../calibration/calibration_controller.gd), [`autoload/save_service.gd`](../autoload/save_service.gd) | **PASS** (`_test_at01_to_at06_calibration_and_obstacles`) |
| **AT-02** | Returning-User Quick Seat Check (`<= 15 s`) updates `O_body` & `Z_body` while preserving reach radii | [`calibration/calibration_controller.gd`](../calibration/calibration_controller.gd) | **PASS** (`_test_at01_to_at06_calibration_and_obstacles`) |
| **AT-03** | Asymmetric Arm Reach (`R_f,L = 0.35 m`, `R_f,R = 0.60 m`) clamps left-hand spawns (`<= 0.85 * 0.35 m`) and two-hand spawns (`<= 0.85 * 0.35 m`) | [`core/comfort_profile.gd`](../core/comfort_profile.gd) | **PASS** (`_test_at01_to_at06_calibration_and_obstacles`) |
| **AT-04** | Obstacle Exclusion Spheres (`r_ex = 0.12 m`) shift or widen spawns so `||p - c_i|| >= 0.12 m` and `y >= y_lap + 0.05 m` | [`core/comfort_profile.gd`](../core/comfort_profile.gd) | **PASS** (`_test_at01_to_at06_calibration_and_obstacles`) |
| **AT-05** | Corrupt `comfort_profile.json` or `session_history.json` backs up to `.bak` and resets cleanly without crashing | [`autoload/save_service.gd`](../autoload/save_service.gd) | **PASS** (`_test_at01_to_at06_calibration_and_obstacles`) |
| **AT-06** | Module Calibrations (`M08` Neck, `M09` Trunk Twist, `M10` Lateral Lean) gate Level B mechanics until completed | [`calibration/calibration_controller.gd`](../calibration/calibration_controller.gd), [`autoload/game_flow.gd`](../autoload/game_flow.gd) | **PASS** (`_test_at01_to_at06_calibration_and_obstacles`) |
| **AT-07** | Zero Unintended Locomotion (`XROrigin3D.position == Vector3.ZERO` and `rotation == Vector3.ZERO`) across all states | [`main.gd`](../main.gd), [`autoload/platform.gd`](../autoload/platform.gd) | **PASS** (`_test_at07_to_at12_safety_and_comfort`) |
| **AT-08** | Hands-to-Lap Auto-Pause triggers after `2.5 s` with both hands `<= y_lap` and speed `< 0.15 m/s` | [`safety/safety_monitors.gd`](../safety/safety_monitors.gd) | **PASS** (`_test_at07_to_at12_safety_and_comfort`) |
| **AT-09** | Excessive Lean Pause triggers after `0.5 s` when horizontal head offset `> 0.25 m` or vertical drop `< -0.20 m` | [`safety/safety_monitors.gd`](../safety/safety_monitors.gd) | **PASS** (`_test_at07_to_at12_safety_and_comfort`) |
| **AT-10** | Level B Stable-Chair Gate substitutes all Level B mechanics with unused Level A mechanics when declined | [`core/session_draw.gd`](../core/session_draw.gd), [`autoload/game_flow.gd`](../autoload/game_flow.gd) | **PASS** (`_test_at07_to_at12_safety_and_comfort`) |
| **AT-11** | No-Trunk Mode excludes `M08`, `M09`, and `M10` from all Score Attack draws (`100/100` simulated draws verified) | [`core/session_draw.gd`](../core/session_draw.gd) | **PASS** (`_test_at07_to_at12_safety_and_comfort`) |
| **AT-12** | Continuous Exercise Rest Reminder triggers at next round boundary after `900 s` (`15 min`) of active play | [`safety/safety_monitors.gd`](../safety/safety_monitors.gd) | **PASS** (`_test_at07_to_at12_safety_and_comfort`) |
| **AT-13** | Balanced 5-Round Session Draw includes all 3 categories (`PUSH_STRIKE`, `REACH_PULL`, `CORE_POSTURE`), `0.5x` repeat weight, and non-adjacent Level B | [`core/session_draw.gd`](../core/session_draw.gd) | **PASS** (`_test_at13_to_at15_session_draw_and_tempo`) |
| **AT-14** | Score Attack 5-Round Progression & Early End Session saves partial completed rounds without penalty | [`autoload/game_flow.gd`](../autoload/game_flow.gd) | **PASS** (`_test_at13_to_at15_session_draw_and_tempo`) |
| **AT-15** | Adaptive Tempo adjusts BPM (`>= 85%` → `+5 BPM`, `< 60%` → `-5 BPM`) within preset `[BPM_min, BPM_max]` | [`core/adaptive_tempo.gd`](../core/adaptive_tempo.gd) | **PASS** (`_test_at13_to_at15_session_draw_and_tempo`) |
| **AT-16** | `M01` Asteroid Brawler enforces segment-to-sphere anti-tunnelling hit + velocity threshold (`v >= 0.65 m/s` Standard) + `+25` solid hit bonus (`v >= 1.25 m/s`) | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m01_asteroid_brawler/m01_mechanic.gd`](../mechanics/m01_asteroid_brawler/m01_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-17** | `M02` Space Fruit Harvester enforces `T_dwell` (`0.20 s` Standard) inside orb + basket drop (`r_basket = 0.16 m`) + `<= 0.18 m` cross-midline cap | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m02_fruit_harvester/m02_mechanic.gd`](../mechanics/m02_fruit_harvester/m02_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-18** | `M03` Glider Pilot enforces normalized bilateral elevation `e_bar` gate match (`<= 0.18`) and symmetry (`|y_L - y_R| <= 0.12 m`) | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m03_glider_pilot/m03_mechanic.gd`](../mechanics/m03_glider_pilot/m03_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-19** | `M04` Turret Gunner charges over `T_hold = 1.5 s` and decays gracefully at `0.5 * dt` when drifting outside `r_aim = 0.12 m` | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m04_turret_gunner/m04_mechanic.gd`](../mechanics/m04_turret_gunner/m04_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-20** | `M05` Cosmic Tug-of-War validates synchronized bilateral pull from `z_front` to `z_back = 0.28 m` (`|z_L - z_R| <= 0.12 m`) | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd`](../mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-21** | `M06` Force Blast validates chest charge (`0.20 s`) + synchronized outward push (`|t_L - t_R| <= 0.14 s`, `v_z >= 0.55 m/s`) | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m06_force_blast/m06_mechanic.gd`](../mechanics/m06_force_blast/m06_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-22** | `M07` Shield Generator Crank accumulates `360°` signed revolutions in radial band (`±0.09 m`) and switches every `3` revolutions | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m07_shield_generator_crank/m07_mechanic.gd`](../mechanics/m07_shield_generator_crank/m07_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-23** | `M08` Recon Scanner locks beacons after `0.70 s` dwell within `±6°` yaw and `±12°` pitch, alternating `Left -> Center -> Right` | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m08_recon_scanner/m08_mechanic.gd`](../mechanics/m08_recon_scanner/m08_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-24** | `M09` Potion Brewer tracks horizontal cauldron stirring (`||p_L - p_R|| <= 0.28 m`) and reverses direction every `2` revolutions | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m09_potion_brewer/m09_mechanic.gd`](../mechanics/m09_potion_brewer/m09_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-25** | `M10` Laser Evader enforces `Side -> Center -> Side` sequence, `±0.08 m` gap tolerance, and pauses on over-lean (`> 0.30 m`) or forward drop (`< -0.15 m`) | [`core/mechanics_math.gd`](../core/mechanics_math.gd), [`mechanics/m10_laser_evader/m10_mechanic.gd`](../mechanics/m10_laser_evader/m10_mechanic.gd) | **PASS** (`_test_at16_to_at25_all_ten_mechanics`) |
| **AT-26** | Exact Scoring & Combo Multiplier (`1.0 + min(streak, 20)/20`, `2.0x` cap at streak 20, resets to `1.0x` on miss) | [`core/scoring.gd`](../core/scoring.gd) | **PASS** (`_test_at26_to_at28_scoring_persistence_and_disclaimer`) |
| **AT-27** | Local JSON Persistence & 50-Session Ring Buffer (`session_history.json` caps at 50 entries and updates `personal_bests`) | [`autoload/save_service.gd`](../autoload/save_service.gd) | **PASS** (`_test_at26_to_at28_scoring_persistence_and_disclaimer`) |
| **AT-28** | Non-Clinical Copy & Disclaimer Gate requires acceptance on boot and displays `"Not a medical device"` without prohibited clinical claims | [`autoload/game_flow.gd`](../autoload/game_flow.gd), [`ui/world_ui.gd`](../ui/world_ui.gd) | **PASS** (`_test_at26_to_at28_scoring_persistence_and_disclaimer`) |
| **MASCOT** | `Floating Mascots.glb` loads 3D hierarchy, builds shoulder/neck pivots, animates all 10 mechanics (`M01`..`M10`), and responds to hand poke | [`mascot/floating_mascot_coach.gd`](../mascot/floating_mascot_coach.gd) | **PASS** (`_test_floating_mascot_coach`) |

---

## 2. Unity ↔ Godot Implementation Parity Table

Per [`03-godot-build.md`](../MarkdownGuideForAIReconstruction/03-godot-build.md) §7, both engines share identical functional behavior and numeric tunables:

| Specification Feature | Unity (`/home/ramirez/XR/Zenofit`) | Godot (`/home/ramirez/XR/GodotMockup/mockup-v-1`) |
| :--- | :--- | :--- |
| **Seated Reference Space** | `TrackingOriginModeFlags.Device` | `XRInterface.XR_REFERENCE_SPACE_TYPE_LOCAL` (`reference_space=1`) |
| **Spec Coordinate Conversion** | Native `+Z` forward, `+ψ` clockwise | `SpecSpace` converts `+Z` Spec ↔ `-Z` Godot & `+ψ` Spec ↔ `-rotation.y` Godot |
| **Anti-Tunnelling Segment Hit** | Custom segment-sphere math | `ZenoGeometry.segment_sphere_hit` via `Geometry3D.get_closest_point_to_segment` |
| **Difficulty Presets** | `ScriptableObject` assets | `DifficultyPreset` (`Resource`) in `resources/difficulty_presets/*.tres` |
| **Save Path & Format** | `Application.persistentDataPath/*.json` | `user://comfort_profile.json` & `user://session_history.json` (`FileAccess` + `JSON`) |
| **3D World-Space UI** | World-Space `Canvas` at `[1.0 m, 1.4 m]` | `ZenoWorldUI` (`SubViewport` + `Sprite3D` quad at `1.15 m` in front of `O_body`) |
| **Interactive Mascot Coach** | Floating Mascot prefab | `FloatingMascotCoach` instancing `res://assets/Floating Mascots.glb` with articulated shoulder/neck pivots |
