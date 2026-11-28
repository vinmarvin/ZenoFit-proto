# ZenoFit — Godot 4.7 Build & AI Reconstruction Rules (v1.0)

## Single Source of Truth
- Active codebase lives ONLY in `godot/` (`4.7.2.stable`, GDScript). Unity was permanently dropped after Week 8.
- **Target Audience (Team Consensus):** **Lazy geeks / couch potatoes**—screen-heavy people who sit for hours in front of monitors (remote workers, programmers, university students, hardcore gamers/*gamers akut*, and homebodies/*ansos* who prefer exercising privately indoors). Lower-body accessibility is preserved naturally as a secondary *curb-cut effect* by keeping every exercise 100% seated and upper-body focused.
- **Course Admin Archive Boundary:** `berkas/BerkasFP/giga-ef234711-2026-final-project-group-4-main/` holds submitted administrative deliverables (**10% total: GA3 = 5%, GA4 = 5%**; Week 8 Proposal is historical). Never treat its legacy Week 8 `README.md` as the active product spec, and never modify files inside that directory unless explicitly instructed.
- **Read Documentation First:** Read `/home/ramirez/XR-FP/AGENTS.md`, `berkas/GodotDocs/AI-Spec/00-README.md`, and the relevant spec or developer guide file before modifying `godot/`. Keep code and docs synchronized 1:1.

## Engine, Platform & Render Budget
- **Engine:** Godot `4.7.2.stable`, **GDScript only**, **`gl_compatibility` renderer**, OpenXR enabled (`Reference Space = Local / Seated`), Dynamic Foveation Level 2, `ETC2/ASTC` VRAM compression.
- **Multi-Platform Targets:** **PICO 4 Ultra** (`preset.0` -> `build/ZenoFit-Godot-Pico4Ultra.apk`), **Meta Quest 2 / 3 / 3S** (`preset.1` -> `build/ZenoFit-Godot-Quest.apk`), and **Linux Desktop Simulator** (`preset.2`). Android package name: `com.zenofit.godot.mockup`.
- **Platform Abstraction:** All XR/vendor calls (OpenXR init, Session Input Lock sampling, haptics, passthrough, recenter, SFX) MUST pass through `godot/autoload/platform.gd`.
- **Render Budget (72–90 FPS standalone mobile VR):**
  - Disable real-time shadows (`SHADOW_CASTING_SETTING_OFF` and `DirectionalLight3D.shadow_enabled = false`) across environment, props, Zeno, and 3D UI panels.
  - Strip all stray kitbash meshes outside `["group3", "group4", "walls", "roof", "group7", "group8"]` in `Environment.glb`.
  - No heavy post-processing (`SSAO`, `SSR`, volumetric fog). Keep draw calls and triangle counts lean.

## Integrated 3D Assets (`godot/assets/`) & Asset Sourcing Policy
- **Asset Sourcing Policy:** All 3D assets included in the final Godot build are exclusively **AI-generated** (`Zeno_WithTexture.glb`, `KarateBoard.glb`) or downloaded from **external asset stores** such as Sketchfab (`Environment.glb`). The GA3 photogrammetry water bottle scan (`ga3/scan_fitted.glb`) is strictly for course documentation/archive purposes and MUST NOT be included in the final Godot build.
- `Environment.glb` — Japanese minimalist calm room downloaded from Sketchfab (`jrevel`, CC BY 4.0; floor shifted `+0.75 m` Z via `DojoEnvironmentLoader`, 6 room groups kept, 28 stray kitbash nodes stripped).
- `Zeno_WithTexture.glb` — Sole textured rigged mascot coach (generated; used exclusively by `FloatingMascotCoach`; `Ground_Ring*` hidden in runtime). Legacy `Floating Mascots.glb` is deleted and must NOT return.
- `KarateBoard.glb` — Interactive wooden breaking board (generated; `604` tris; `Board_Intact` + `Board_Half_Left`/`Right` + `Splinter_1..6` + `Break` animation) managed via `KarateBoardProp`.

## Coordinate Space, Stationary Camera & Ergonomics
- **SpecSpace vs. Godot:** `SpecSpace` is **left-handed** (`+X` right, `+Y` up, `+Z` FORWARD; positive yaw = turn RIGHT). Godot is **right-handed** (`-Z` forward; positive yaw = turn LEFT). Convert ONLY via `godot/core/spec_space.gd`.
- **Stationary `BodyFrame` (Anti-Wobble Rule):** Rebuild `BodyFrame` ONLY on explicit boot/session init, 3-step Calibration (`SEAT_ANCHOR`), Quick Recenter (`pose_recentered`), or user View Recenter. NEVER re-derive `BodyFrame` origin or `origin_spec.y` per frame or from camera head pitch/look-vector Y. Never move, rotate, or scale `XROrigin3D` during gameplay.
- **FoV-Safe Zeno Placement:** `FloatingMascotCoach.compute_fov_safe_anchor()` MUST keep Zeno within horizontal viewing half-angle `<= 24°` (`MAX_FOV_HALF_ANGLE_DEG = 23.0`) across all states and configurable HUD distances so he is never cropped outside standalone VR lenses, and provide live procedural demos for all 11 exercises (`ExerciseId 1..11`).
- **Configurable HUD Ergonomics:** Settings expose `hud_distance_m` (`1.30–2.20 m`, default `1.65 m`) and `hud_scale` (`0.85–1.20x`, default `1.00x`). All spatial panels live statically in `BodyFrame` (world-locked, never head-locked).

## Gameplay, 11 Curated Exercises, Input Lock & Anti-Cheat
- **Standard Non-Swivel Chair Assumption:** All 11 curated upper-body seated exercises assume a stationary desk/gaming chair:
  1. `Board Smash` (`Active`, Level A) — Front Jab/Cross, Side Hook, High Uppercut (`KarateBoard.glb`).
  2. `Wide Split` (`Active`, Level A) — Chest Opener in 20° scapular plane (`KarateBoard.glb` twin boards).
  3. `Sky Reach` (`Mobility`, Level A) — Diagonal overhead reach clamped to `<= 45°` gaze elevation.
  4. `Orbit Flow` (`Mobility`, Level A) — Smooth shoulder circles with signed-angle anti-cheat (`min_radius >= 0.12 m`).
  5. `Wrist Twist` (`Mobility`, Level A) — Forearm steady + wrist roll dials (`±target_deg`).
  6. `Torso Twist` (`Posture`, Level B) — Chest guard (`<= 0.32 m`) + head-chest yaw sync (`KarateBoard.glb` side target).
  7. `Horizon Gaze` (`Posture`, Level B) — Slow neck scan (`<= 60°/s`, pitch `<= 20°`, `1.0 s` dwell).
  8. `Shoulder Press` (`Active`, Level A, Two-Set `2×12`) — Vertical overhead `Box` press along `MechanicalTensionGuide` (optional dumbbell note).
  9. `Bicep Curl` (`Active`, Level A, Two-Set `2×12`) — Curved `Orb` elbow flexion/extension along `MechanicalTensionGuide` (optional dumbbell note).
  10. `Arm Circles` (`Mobility`, Level A, Two-Set `2×12`) — Dual side-plane (`Y-Z`) circular tension rings + 4 checkpoint orbs + signed-direction check (optional dumbbell note).
  11. `Lateral Raise` (`Active`, Level A, Two-Set `2×12`) — Quarter-sine lateral `Box` raise/lower along `MechanicalTensionGuide` (no dumbbell note).
- **Modes & Pacing:** `Quick Break` (5-round curated mix covering `Active`, `Mobility`, `Posture` at `30 s`/round for timed exercises and explicit `2 × 12` completion via `require_explicit_round_completion` for two-set exercises, with non-consecutive Level B) OR single exercise (`45 s` timed / `2 × 12` two-set) from `Exercise Library` with `All / Active / Mobility / Posture` filter.
- **Strict Session Input Lock (`Platform.sample_input_pose`):** Player chooses `Controllers` or `Hand Tracking` before/outside rounds. During a session, input source NEVER auto-switches silently on momentary drop; tracking loss triggers `PauseReason.INPUT_LOST` cleanly.
- **NO Raycasting During Gameplay:** UI pointer raycast is enabled ONLY in UI/Menu/Paused/Calibration states (`Main.is_ui_raycast_enabled()`). During `ROUND_PLAY`, all hits require genuine 3D spatial kinematics + anti-cheat checks in `MechanicsMath` and `MechanicalTensionGuide` corridor proximity / signed-direction checks.
- **Level B Safety:** `Torso Twist` and `Horizon Gaze` MUST NEVER reward fast whipping motion; fast head turns (`> 60°/s`) pause dwell and show a calm cue.

## Spatial UI (`berkas/UI.pdf`), Cleanliness & Attribution
- **11-Screen Dark-Sage Glass Flow:** `Welcome`, `Main Menu`, `Exercise Library` (adaptive compact 4-column grid when `> 8` items), `Exercise Preview` (with optional dumbbell guidance card on `Shoulder Press`, `Bicep Curl`, `Arm Circles`), `Calibration` (3-step `<= 15 s`), `Active HUD` (+ compact bottom cue), `Pause`, `Results`, `Settings`, `Tutorial`, `Credits`, `Exit Confirm` rendered via `DojoPanel3D` + `ZenoWorldUI`.
- **Zero Debug Strings in VR:** Never display internal IDs (`M01..M10`), desktop key hints (`[Tab]`, `[Space]`), legacy placeholders, or removed assets in VR 3D panels or target meshes.
- **Verified Attribution:** Credits MUST attribute **Institut Teknologi Sepuluh Nopember (ITS)**, environment artist **jrevel**, and the final-build 3D assets (`KarateBoard.glb`, `Zeno_WithTexture.glb`). Never display stale/wrong school names.

## Automated Acceptance Tests
Refresh the local Godot class cache on fresh checkouts or after pulling new `class_name` scripts, then run the suite after every code change before reporting results:
```bash
godot --headless --xr-mode off --path godot --import
godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
```
Target: `TOTAL PASSED: 101 | TOTAL FAILED: 0` (`16` test groups) with zero Godot parse errors or ObjectDB leaks.

## Non-Medical Product Boundary
- ZenoFit is an active-break movement & posture wellness game, NOT a medical or therapeutic device. Never add clinical diagnosis, pain-treatment, or optical strain-cure claims in UI copy, code, or docs.
