# ZenoFit v1.0 — AI Specification & Traceability Root

> **Single Source of Truth:** This folder documents the locked design, mathematics, ergonomics, UI, asset integration, and acceptance contracts for **ZenoFit v1.0** implemented in [`godot/`](../../../godot/). Keep documentation and source code synchronized 1:1.

---

## 1. Product Goal & Target Audience

- **Core Product Goal:** ZenoFit is a seated upper-body VR *active-break* game built for **lazy geeks / couch potatoes**—people who spend excessive hours seated in front of monitors and avoid traditional exercise:
  - Desk/screen workers and university students,
  - Hardcore gamers (*gamers akut*),
  - Homebodies / socially avoidant users (*ansos*) who prefer private indoor movement over gyms.
- **Secondary Benefit (*Curb-Cut Effect*):** Keeping every exercise 100% seated, upper-body focused, and operable on a **standard non-swivel chair** naturally preserves accessibility for users with lower-body mobility limitations.
- **Course Admin Archive Boundary:** [`berkas/BerkasFP/giga-ef234711-2026-final-project-group-4-main/`](../../BerkasFP/giga-ef234711-2026-final-project-group-4-main/) holds historical grading archive deliverables (**10% total: GA3 = 5%, GA4 = 5%**; Week 8 Proposal is already past/historical). Never overwrite submitted files inside that folder or treat its legacy Week 8 draft as active spec.
- **Non-Medical Product Boundary:** ZenoFit is an active-break wellness game, NOT a medical or clinical device.

---

## 2. Locked Architectural Decisions (`v1.0`)

| Domain | Locked Decision | Source of Truth |
| :--- | :--- | :--- |
| **Engine & Renderer** | Godot `4.7.2.stable`, GDScript only, `gl_compatibility`, OpenXR `Local / Seated Reference Space`, Dynamic Foveation Level 2 | `godot/project.godot` |
| **Platform Targets** | PICO 4 Ultra (`preset.0`), Meta Quest 2/3/3S (`preset.1`), Linux Desktop Simulator (`preset.2`); package `com.zenofit.godot.mockup` | `godot/export_presets.cfg`, `godot/autoload/platform.gd` |
| **Chair Assumption** | Standard stationary **non-swivel** desk/gaming chair | `godot/core/mechanics_math.gd` |
| **Core Loop** | **Hybrid Rhythm-Flow**: **11 curated exercises** (`7` timed rhythm-flow exercises: `Quick Break` 5-round mix `30.0 s`/round OR single exercise `45.0 s`; plus `4` two-set mechanical-tension exercises requiring explicit completion of `2 × 12` reps via `require_explicit_round_completion`) | `godot/core/session_draw.gd`, `godot/autoload/game_flow.gd`, `godot/mechanics/two_set_tension_mechanic.gd` |
| **Input Strategy** | **Strict Session Input Lock** (`Controllers` primary, `Hand Tracking` optional); never silently auto-switches mid-session; `INPUT_LOST` pauses cleanly | `godot/autoload/platform.gd`, `godot/main.gd` |
| **Gameplay Anti-Cheat** | UI pointer raycast strictly **OFF** during `ROUND_PLAY`; all hits require 3D spatial kinematics + anti-cheat checks (`MechanicsMath`, `MechanicalTensionGuide` corridor proximity & signed-direction checks) | `godot/main.gd`, `godot/core/mechanics_math.gd`, `godot/mechanics/mechanical_tension_guide.gd` |
| **Camera Stability** | **Stationary `BodyFrame`**: anchored only at initial pose, Calibration Step 1, or explicit Recenter — zero vertical/lateral wobble on head pitch/yaw | `godot/core/body_frame.gd`, `godot/main.gd` |
| **Mascot FoV Safety** | Textured rigged `Zeno_WithTexture.glb` only (`Floating Mascots.glb` removed), `Ground_Ring*` hidden, horizontal FoV angle clamped `<= 23.0°` (`<= 24°` verified), live procedural demonstrations for all `11` exercises (`ExerciseId 1..11`) | `godot/mascot/floating_mascot_coach.gd` |
| **Spatial UI System** | `UI.pdf` Dark-Sage Glassmorphism (`11` screens + compact gameplay HUD & bottom cue), adaptive compact 4-column `Exercise Library` grid (`> 8` items), optional dumbbell guidance card on `Exercise Preview`, configurable `hud_distance_m` (`1.30–2.20 m`) & `hud_scale` (`0.85–1.20x`), **zero debug codes (`M01..M10`)** in VR | `godot/ui/dojo_panel_3d.gd`, `godot/ui/world_ui.gd` |
| **Integrated 3D Assets** | All final-build 3D assets are generated (`Zeno_WithTexture.glb`, `KarateBoard.glb`) or downloaded from external stores (`Environment.glb` via Sketchfab); GA3 water bottle is documentation-only and excluded from the build | `godot/core/dojo_environment_loader.gd`, `godot/mechanics/karate_board_prop.gd` |

---

## 3. Code ↔ Spec Traceability Matrix

Every active script and resource in `godot/` maps 1:1 to a specification or guide document:

| Godot Script / Resource | Class / Autoload | Spec / Developer Guide Section |
| :--- | :--- | :--- |
| `godot/project.godot`, `godot/export_presets.cfg`, `godot/openxr_action_map.tres`, `godot/main.tscn` | Project config & root `XROrigin3D` | `AI-Spec/00-README.md`, `DeveloperGuide/02-Setup-Testing-And-Build.md` |
| `godot/main.gd` | Scene coordinator (`XROrigin3D`) | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md`, `DeveloperGuide/01-Architecture-And-How-It-Works.md` |
| `godot/autoload/event_bus.gd` | `EventBus` | `DeveloperGuide/01-Architecture-And-How-It-Works.md` |
| `godot/autoload/platform.gd` | `Platform` | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §4 |
| `godot/autoload/save_service.gd` | `SaveService` (`SaveServiceClass`) | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §6 |
| `godot/autoload/game_flow.gd` | `GameFlow` (`GameFlowController`) | `AI-Spec/01-Gameplay-And-Exercises.md` §1, `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §2 |
| `godot/core/enums.gd` | `ZenoEnums` | `AI-Spec/01-Gameplay-And-Exercises.md` §3, `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §2 |
| `godot/core/spec_space.gd` | `SpecSpace` | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §1 |
| `godot/core/body_frame.gd` | `BodyFrame` | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §2 |
| `godot/core/comfort_profile.gd` | `ComfortProfile` | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §3 |
| `godot/core/difficulty_preset.gd`, `resources/difficulty_presets/*.tres` | `DifficultyPreset` | `AI-Spec/01-Gameplay-And-Exercises.md` §2 |
| `godot/core/dojo_environment_loader.gd` | `DojoEnvironmentLoader` | `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §4 |
| `godot/core/geometry.gd` | `ZenoGeometry` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.1 |
| `godot/core/mechanics_math.gd` | `MechanicsMath` | `AI-Spec/01-Gameplay-And-Exercises.md` §4 |
| `godot/core/adaptive_tempo.gd` | `AdaptiveTempo` | `AI-Spec/01-Gameplay-And-Exercises.md` §2.2 |
| `godot/core/scoring.gd` | `ZenoScoring` | `AI-Spec/01-Gameplay-And-Exercises.md` §2.1 |
| `godot/core/session_draw.gd` | `SessionDraw` | `AI-Spec/01-Gameplay-And-Exercises.md` §1.2 |
| `godot/calibration/calibration_controller.gd` | `CalibrationController` | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §3 |
| `godot/safety/safety_monitors.gd` | `SafetyMonitors` | `AI-Spec/02-Coordinate-Space-Calibration-And-Safety.md` §5 |
| `godot/mascot/floating_mascot_coach.gd` | `FloatingMascotCoach` | `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §3 |
| `godot/ui/dojo_panel_3d.gd` | `DojoPanel3D` | `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §1 |
| `godot/ui/world_ui.gd` | `ZenoWorldUI` | `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §2 |
| `godot/mechanics/mechanic_base.gd` | `MechanicBase` | `DeveloperGuide/01-Architecture-And-How-It-Works.md` §3 |
| `godot/mechanics/karate_board_prop.gd` | `KarateBoardProp` | `AI-Spec/03-Spatial-UI-Mascot-And-Assets.md` §4, `DeveloperGuide/01-Architecture-And-How-It-Works.md` §4 |
| `godot/mechanics/mechanical_tension_guide.gd` | `MechanicalTensionGuide` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.8 |
| `godot/mechanics/two_set_tension_mechanic.gd` | `TwoSetTensionMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.8 |
| `godot/mechanics/directional_two_set_mechanic.gd` | `DirectionalTwoSetMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.8 |
| `godot/mechanics/board_smash/board_smash.gd` | `BoardSmashMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.1 |
| `godot/mechanics/wide_split/wide_split.gd` | `WideSplitMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.2 |
| `godot/mechanics/sky_reach/sky_reach.gd` | `SkyReachMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.3 |
| `godot/mechanics/orbit_flow/orbit_flow.gd` | `OrbitFlowMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.4 |
| `godot/mechanics/wrist_twist/wrist_twist.gd` | `WristTwistMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.5 |
| `godot/mechanics/torso_twist/torso_twist.gd` | `TorsoTwistMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.6 |
| `godot/mechanics/horizon_gaze/horizon_gaze.gd` | `HorizonGazeMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.7 |
| `godot/mechanics/shoulder_press/shoulder_press.gd` | `ShoulderPressMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.9 |
| `godot/mechanics/bicep_curl/bicep_curl.gd` | `BicepCurlMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.10 |
| `godot/mechanics/arm_circles/arm_circles.gd` | `ArmCirclesMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.11 |
| `godot/mechanics/lateral_raise/lateral_raise.gd` | `LateralRaiseMechanic` | `AI-Spec/01-Gameplay-And-Exercises.md` §4.12 |
| `godot/tests/run_acceptance_tests.gd`, `test_acceptance_suite.gd` | `ZenoAcceptanceSuite` | `AI-Spec/04-Acceptance-Tests-And-Traceability.md` |
| `godot/scripts/cast_vr_screen.sh` | USB Screen Cast script | `DeveloperGuide/03-USB-Screencast-And-Recording.md` |

---

## 4. Document Map

- **AI Specifications (`AI-Spec/`):**
  - [`00-README.md`](./00-README.md) — Decisions & Code ↔ Spec Traceability Matrix (this file)
  - [`01-Gameplay-And-Exercises.md`](./01-Gameplay-And-Exercises.md) — Core loop, scoring, tempo, and all 11 curated exercises + `MechanicsMath` & `MechanicalTensionGuide` formulas
  - [`02-Coordinate-Space-Calibration-And-Safety.md`](./02-Coordinate-Space-Calibration-And-Safety.md) — `SpecSpace`, stationary `BodyFrame`, 3-step calibration, Session Input Lock, Safety Monitors, `SaveService`
  - [`03-Spatial-UI-Mascot-And-Assets.md`](./03-Spatial-UI-Mascot-And-Assets.md) — `UI.pdf` Dark-Sage UI, 11-screen flow, HUD ergonomics, FoV-safe Zeno, and 3D assets
  - [`04-Acceptance-Tests-And-Traceability.md`](./04-Acceptance-Tests-And-Traceability.md) — Automated headless test suite (`108` assertions across `17` test functions)
- **Developer Guides (`DeveloperGuide/`):**
  - [`01-Architecture-And-How-It-Works.md`](../DeveloperGuide/01-Architecture-And-How-It-Works.md)
  - [`02-Setup-Testing-And-Build.md`](../DeveloperGuide/02-Setup-Testing-And-Build.md)
  - [`03-USB-Screencast-And-Recording.md`](../DeveloperGuide/03-USB-Screencast-And-Recording.md)
