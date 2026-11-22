# 03 — Godot 4.7 Multi-Platform Build Guide (PICO 4 Ultra & Meta Quest 3)

> **Version:** 0.4 (Godot is now the **sole active engine**; Unity was deleted in commit `1dbc35c`.)
> Legend: **[S]** source/research · **[D]** locked decision · **[P]** tunable default · **[V]** verify on hardware.

---

## 1. Engine & Platform Decisions

| ID | Decision | Notes |
|---|---|---|
| G-01 | **Godot 4.7+ (`4.7.2.stable`)** | Active project lives at `godot/project.godot`. |
| G-02 | Language: **GDScript only** | Clean Android ARM64 export, zero C# export friction. |
| G-03 | Renderer: **Compatibility (`gl_compatibility`)** + `ETC2/ASTC` VRAM compression + Dynamic Foveation Level 2 | Best stability & frame times on Android OpenXR headsets. |
| G-04 | XR API: **OpenXR** (`Reference Space = Local / Seated`) + **Godot OpenXR Vendors plugin** (`godot/addons/godotopenxrvendors/`) | Single codebase exports to **PICO 4 Ultra** (`preset.0`) and **Meta Quest 2/3/3S** (`preset.1`). |
| G-05 | Android package name: `com.zenofit.godot.mockup` | No internet permission (`permissions/internet=false`). |
| G-06 | Automated tests: headless GDScript suite `godot/tests/run_acceptance_tests.gd` | Runs `AT-01`–`AT-35` without needing a headset. |

---

## 2. Coordinate Space & Yaw Traps (`core/spec_space.gd`)

1. **Z-Axis Handedness:** Spec space uses **`+Z` forward** (left-handed). Godot uses **`-Z` forward** (right-handed).
   - `SpecSpace.to_godot(p_spec) -> Vector3(p_spec.x, p_spec.y, -p_spec.z)`
   - Example: `z = +0.51 m` in spec → `z = -0.51 m` in Godot.
2. **Yaw Sign:** Spec positive yaw = turning **RIGHT** (clockwise from above). Godot positive `rotation.y` = turning **LEFT** (counter-clockwise).
   - `SpecSpace.yaw_deg_to_godot_deg(psi) -> -psi`
   - Example: `psi_max_R = +40°` in spec → `rotation.y = -40°` in Godot.

**Hard Rule:** Perform ALL gameplay math in `SpecSpace` / `BodyFrame`, and convert at the rendering/input boundary ONLY via `godot/core/spec_space.gd`.

---

## 3. Active Godot Project Layout (`godot/`)

```text
godot/
├─ project.godot
├─ openxr_action_map.tres        # Includes pico4s_controller, oculus/touch_controller, & ext/hand_interaction_ext
├─ export_presets.cfg            # preset.0 PICO 4 Ultra, preset.1 Meta Quest, preset.2 Linux Desktop
├─ main.tscn / main.gd           # XROrigin3D coordinator, hybrid hand/controller tracking, desktop sim
├─ addons/godotopenxrvendors/    # OpenXR vendor loaders (Meta & PICO)
├─ assets/                       # In-engine 3D models, Zen Dojo scene, Dojo audio SFX/BGM
├─ autoload/                     # event_bus.gd, platform.gd, save_service.gd, game_flow.gd
├─ core/                         # Pure math: spec_space.gd, body_frame.gd, comfort_profile.gd,
│                                # difficulty_preset.gd, geometry.gd, adaptive_tempo.gd, scoring.gd,
│                                # session_draw.gd, mechanics_math.gd, enums.gd
├─ calibration/                  # calibration_controller.gd
├─ safety/                       # safety_monitors.gd
├─ mascot/                       # floating_mascot_coach.gd (Zeno procedural coach)
├─ mechanics/                    # mechanic_base.gd + m01..m10 folders
├─ resources/difficulty_presets/ # gentle.tres, standard.tres, active.tres
├─ ui/                           # world_ui.gd (3D HUD + Main Menu + Routine Picker + Desktop overlay)
├─ scripts/cast_vr_screen.sh     # Live 60 FPS ADB USB screencast & MP4 recorder
└─ tests/                        # run_acceptance_tests.gd, test_acceptance_suite.gd
```

*Documentation lives outside `godot/` in `berkas/GodotDocs/` so `godot/` stays clean code/assets only.*

---

## 4. Hybrid OpenXR Input Architecture (Hand Tracking Primary + Controller Fallback) **[D]**

Both PICO 4 Ultra and Meta Quest 3 support standard OpenXR Hand Tracking (`openxr/extensions/hand_tracking=true` and `hand_interaction_profile=true` are already enabled in `godot/project.godot`).

### 4.1 Unified Hand Input Abstraction (`Platform` / `Main`)
Do NOT read controller nodes directly inside mechanics. Instead, `main.gd` resolves an active `HandInputFrame` each tick for Left and Right hands:
- **Priority 1 — OpenXR Hand Tracking (`XRHandTracker` `/user/hand_tracker/left|right`):**
  - `position_local_spec`: Index-tip (for poke/reach) or Palm center (for punch/push/row) transformed via `BodyFrame.from_godot_world()`.
  - `wrist_roll_deg`: Derived from `XRHandTracker.HAND_JOINT_WRIST` / `HAND_JOINT_PALM` basis roll (used by `M09` Tea Ceremony Pour).
  - `is_pinching`: Thumb-tip to Index-tip distance `<= 0.025 m` OR `hand_interaction_ext` `pinch_ext` action (for menu/calibration confirm).
  - `is_grasping`: Average finger curl / `grasp_ext` action (for `M05` Temple Bell Pull, `M09` Tea Pour, `M10` Bamboo Sway).
  - `is_tracked`: `tracker.has_tracking_data` (used for lap auto-pause fallback if hands drop below camera FoV).
- **Priority 2 — Handheld Controller Fallback (`XRController3D` `left_hand` / `right_hand`):**
  - Automatically active whenever `XRController3D.get_has_tracking_data()` is true and hand tracker is inactive (e.g., low-light rooms or user preference).
  - `is_pinching` ← `trigger_click` / `ax_button`; `is_grasping` ← `grip_click` (`grip > 0.5`).
  - Haptics (`Platform.play_haptic_*`) fire only when controllers are active; Dojo Audio + Visual Juice fires in **both** modes!
- **Priority 3 — Desktop Simulator:** Mouse + Keyboard (`Q/E + Mouse`, `Tab`, `Space`, `K`, `L`, `R`, `M`, `Esc`).

### 4.2 Zero-Raycast Rule During `ROUND_PLAY`
- Any UI raycast node (if used for menus) MUST set `enabled = false` and `visible = false` whenever `GameFlow.current_state == ROUND_PLAY`.

---

## 5. Multi-Platform Render Budget (PICO 4 Ultra, Meta Quest 3, & Quest 2 Baseline) **[D]**

Both PICO 4 Ultra and Meta Quest 3 run **Snapdragon XR2 Gen 2**, while lab testing may also include **Quest 2** (`72 Hz = 13.89 ms/frame` budget; `90 Hz = 11.11 ms/frame`). Target the strict budget below so every headset holds locked frame rate without reprojection or motion sickness:

| Budget Item | Hard Limit | Implementation Rules |
|---|---|---|
| **Total Scene Triangles** | **<= 200,000 – 350,000 tris/frame** | Zen Dojo room `<= 120k tris`; Zeno mascot `~19.9k tris` (use optimized GA3 mesh, NEVER the unoptimized 66.4k mesh); active gameplay props `< 3k tris` each. |
| **Draw Calls** | **<= 80 – 120 / frame** | Merge static Dojo meshes sharing materials in Blender; reuse `StandardMaterial3D` instances across targets. |
| **Lighting & Shadows** | **Max 1 `DirectionalLight3D`**; **NO real-time shadows** on static Dojo | Use baked lightmaps or soft ambient + simple unshaded/fake contact shadows. Real-time shadows are the #1 mobile VR FPS killer. |
| **Textures** | `<= 2048×2048` (Dojo walls/floor), `<= 512–1024` (props) | Never ship `4096×4096` textures on small props in the active scene. Keep `ETC2/ASTC` compression enabled. |
| **Post-Processing** | **Disabled** (no SSAO, SSR, Volumetric Fog, heavy Glow) | MSAA `2x` max. |
| **Particles & VFX** | **<= 30 particles** per hit burst (`CPUParticles3D` / `GPUParticles3D`, unshaded) | Pre-warm particle materials at Boot to avoid mid-round shader stutter. |

---

## 6. Headless Testing & Export Commands

- **Run Acceptance Tests:**
  ```bash
  godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
  ```
- **USB Live Screen Cast & Recording (PICO 4 Ultra / Meta Quest):**
  ```bash
  ./godot/scripts/cast_vr_screen.sh
  ./godot/scripts/cast_vr_screen.sh record demo.mp4
  ```
- **Export Presets (`godot/export_presets.cfg`):**
  - `PICO 4 Ultra (Android OpenXR)` → `godot/build/ZenoFit-Godot-Pico4Ultra.apk` (`enable_pico_plugin=true`, `pico_xr_features/hand_tracking=true`)
  - `Meta Quest (Android OpenXR)` → `godot/build/ZenoFit-Godot-Quest.apk` (`enable_meta_plugin=true`, `meta_xr_features/hand_tracking=1`)
  - `Linux Desktop Simulator` → `godot/build/ZenoFit-Godot-Desktop.x86_64`
