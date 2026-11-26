# 03 — Spatial UI (`UI.pdf`), FoV-Safe Zeno Mascot & Integrated Assets

> **Sources of Truth:** `UI.pdf`, `Credits.txt`, `godot/ui/dojo_panel_3d.gd`, `godot/ui/world_ui.gd`, `godot/mascot/floating_mascot_coach.gd`, `godot/core/dojo_environment_loader.gd`, `godot/mechanics/karate_board_prop.gd`.

---

## 1. Dark-Sage Glassmorphism Design System (`DojoPanel3D`)

All 3D VR menus render high-DPI Godot `Control` trees inside a transparent `SubViewport` mapped onto an unshaded double-sided `QuadMesh` (`SHADOW_CASTING_SETTING_OFF`), supporting exact ray-to-UV intersection (`DojoPanel3D.intersect_ray`) even under scaled `ZenoWorldUI` transforms.

| Token Constant | Color (`RGBA`) | Purpose |
| :--- | :--- | :--- |
| `COL_BG_GLASS` | `(0.08, 0.12, 0.10, 0.86)` | Translucent dark-sage glass panel background (`corner_radius = 24`) |
| `COL_BORDER` | `(0.30, 0.44, 0.37, 0.72)` | `2 px` frosted glass rim |
| `COL_CARD_BG` | `(0.11, 0.16, 0.13, 0.84)` | Elevated card / exercise tile fill (`corner_radius = 16`) |
| `COL_CARD_BORDER` | `(0.28, 0.42, 0.35, 0.56)` | Subtle `1 px` card outline |
| `COL_PRIMARY` | `(0.76, 0.87, 0.75, 0.96)` | Sage-mint primary CTA fill (with dark `COL_PRIMARY_TEXT` `(0.07, 0.12, 0.09)`) |
| `COL_SELECTED` | `(0.20, 0.48, 0.43, 0.92)` | Active filter / setting pill highlight |
| `COL_DESTRUCTIVE` | `(0.38, 0.17, 0.19, 0.88)` | End session / exit / reset actions |
| `COL_TEXT_MAIN` | `(0.94, 0.97, 0.95)` | High-contrast primary copy |
| `COL_TEXT_MUTED` | `(0.68, 0.77, 0.72)` | Secondary metadata & subtitles |
| `COL_ACCENT_TEAL` | `(0.45, 0.82, 0.74)` | Section eyebrows & category pills |

---

## 2. 11-Screen Spatial Flow & HUD Ergonomics (`ZenoWorldUI`)

### 2.1 Complete Screen & State Flow (`ZenoEnums.AppState`)
1. `WELCOME` — Two-column onboarding hero: Zeno welcome, calibration readiness pill, quick `Controllers / Hand Tracking` selector, `Continue` + `Calibration` / `Recenter`.
2. `MAIN_MENU` — Left/Right hub (`1.38 × 0.80 m` menu card at `x = -0.20 m` so Zeno sits clear on the right): **Start Quick Break (5 Rounds)**, **Exercise Library**, `Calibration`, `Settings`, `How It Works`, `Credits`, `Exit` + weekly summary (`sessions_count`, `total_minutes`, `best_score`).
3. `EXERCISE_SELECT` — Category filter chips (`All`, `Active`, `Mobility`, `Posture`) + clean exercise cards (zero `M01..M10` internal IDs!).
4. `EXERCISE_PREVIEW` — Centered card (`1.38 × 0.80 m`) with category, safety note, body area, 3 readable steps while **Zeno demonstrates the exact exercise live inside the left preview column**, `Start Exercise (45s)`.
5. `CALIBRATION` — 3-step guided setup (`1/3 Seated Posture`, `2/3 Comfort Reach L & R`, `3/3 Rest & Lap Zone`) with `Confirm Step` / `Skip (One-Hand Mode)` / `Cancel`.
6. `ROUND_INTRO / ROUND_PLAY / ROUND_OUTRO` — Uncluttered **Compact Top HUD** (`1.14 × 0.16 m`, `1020 × 144 px` at `y = +0.45 m`, `z = hud_dist + 0.14 m`) showing single-line exercise title, round progress bar, single-line countdown, and live score/streak, paired with **Compact Bottom Cue Bar** (`0.90 × 0.095 m`, `820 × 86 px` at `y = -0.45 m`).
7. `PAUSED` — Polished centered overlay (`0.96 × 0.72 m`, `920 × 690 px` at `x = -0.08 m`) showing `SESSION PAUSED` badge, `"Take your time."`, 3 live progress tiles (`EXERCISE`, `TIME LEFT`, `CURRENT SCORE`), prominent `Resume Workout` CTA, `2×2` action grid (`Restart Exercise`, `Settings`, `Recenter View`, `Main Menu`), and `Exit Experience`; active `arena_root` props automatically hide while paused.
8. `RESULTS` — Session complete card: total score, accuracy rank (`S+`..`C`), `NEW BEST` badge if earned, covered muscle/mobility areas pill list, `Play Again`, `Main Menu`.
9. `SETTINGS` — 4 clean tabs (`Comfort`, `Input`, `Audio`, `Display`): difficulty tier, hand mode, input mode lock, haptics/audio sliders, rest reminder interval, **HUD Distance**, **HUD Scale**, and `Reset All Local Data`.
10. `TUTORIAL` — Paginated 3-page guide (`Welcome & Seated Play`, `Safe Movement Pace`, `Pause Anytime`).
11. `CREDITS` & `EXIT_CONFIRM` — Dedicated exit confirmation modal (`0.84 × 0.56 m`, `760 × 506 px` centered) and accurate credits naming **Institut Teknologi Sepuluh Nopember (ITS)**, environment creator **`jrevel`** (CC BY 4.0 / Sketchfab), `Zeno_WithTexture.glb`, and `KarateBoard.glb`.

### 2.2 Ergonomics Clamping & Zero-Debug VR Rules
- **Configurable HUD Ergonomics (`GameFlow.adjust_hud_distance`, `adjust_hud_scale`):**
  - `hud_distance_m`: clamped `[1.30, 2.20] m`, default `1.65 m` (`step ±0.10 m`).
  - `hud_scale`: clamped `[0.85, 1.20]x`, default `1.00x` (`step ±0.05x`).
  - World-locked smoothly inside stationary `BodyFrame` (`board_y = 0.22 m` in menus, `0.16 m` in rounds). Never follows head pitch/yaw.
- **Zero Debug Text in VR:** `NO-DEBUG-UI` test asserts zero occurrences of `M01..M10`, `[Tab]`, `[Space]`, `Fruit Harvester`, `Makiwara`, or `Politeknik` anywhere inside `DojoPanel3D` or exercise strings.
- **Desktop Helper Strip:** 2D `CanvasLayer` shortcut hint + top-right `[Auto-Hit | Next | Pause]` quick bar is visible **ONLY** when `Platform.is_xr_active == false`.

---

## 3. FoV-Safe Textured Zeno Mascot (`FloatingMascotCoach`)

- **Model:** Uses `res://assets/Zeno_WithTexture.glb` exclusively (bundled textured rig with `Arm_L`, `Arm_R`, `Head`, `Eye_L/R`, `EyeHappy_L/R`, `Mouth_Smile/Open`, `Ring_1..3`). Legacy `Floating Mascots.glb` was deleted permanently.
- **Ground Rings Hidden:** `Ground_Ring` and `Ground_Ring_Inner` are set `.visible = false` so floating Zeno stays clean beside panels; all mascot meshes set `cast_shadow = SHADOW_CASTING_SETTING_OFF`.
- **FoV-Safe Horizontal Clamp (`compute_fov_safe_anchor`):**
  - Enforces horizontal viewing half-angle `<= MAX_FOV_HALF_ANGLE_DEG (23.0°)` across all HUD distances (`1.30–2.20 m`) and app states without overlapping menu buttons:
    - `EXERCISE_PREVIEW`: sits inside left preview column (`px = -min(0.34, preview_z * tan(18°))`, `scale = 0.145`, `facing = +16°`).
    - `ROUND_INTRO / PLAY / OUTRO`: sits gently off-center right (`rx = min(0.60, play_z * tan(20°))`, `scale = 0.145`, `facing = -20°`).
    - Menus (`WELCOME`, `MAIN_MENU`, etc.): `z_menu = clamp(hud_dist + 0.08, 1.62, 2.24)`, `mx = min(0.72, z_menu * tan(23°))`, `scale = 0.140`, `facing = -22°` (clear of panel right edge at `+0.49 m`).
  - Guarantees Zeno never sits cropped outside VR headset lenses (verified `<= 24°` across 12 state×distance combinations in `MASCOT-FOV`).
- **Live 7-Exercise Demonstrations (`_animate_joints`):** Animates distinct procedural joint trajectories for every `ExerciseId` `1..7` during `EXERCISE_PREVIEW`, `ROUND_INTRO`, and gentle cheering/sway during `ROUND_PLAY`.
- **High-Five Poke Reaction & Temporary Bubble:** Outside `ROUND_PLAY`, touching within `POKE_RADIUS_M = 0.22 m` triggers happy eyes + bounce + brief speech bubble (`bubble_timer_s = 2.0 s`, auto-hides afterward).

---

## 4. Integrated 3D Assets & Render Budget

| Asset (`godot/assets/`) | Role | Structural / Optimization Rules |
| :--- | :--- | :--- |
| **`Environment.glb`** | Calm Japanese minimalist tatami/shoji room (Sketchfab) | `DojoEnvironmentLoader.load_and_clean_dojo_environment()`: shifts `scene_root` `+0.75 m` Z to center player in room; keeps strictly 6 nodes (`group3`, `group4`, `walls`, `roof`, `group7`, `group8`) and frees 28 stray external pieces (`pCube*`, etc.); sets `CULL_DISABLED`, `roughness >= 0.65`, shadow casting `OFF`. |
| **`Zeno_WithTexture.glb`** | Sole textured rigged mascot (Generated) | Loaded via `FloatingMascotCoach`; `Ground_Ring*` hidden; shadow casting `OFF`. |
| **`KarateBoard.glb`** | Breaking pine karate board (Generated, `604` tris, `0.28 × 0.25 × 0.018 m`) | Loaded via `KarateBoardProp`; attaches emissive hand-cue top/bottom rims (`Mint` left / `Amber` right); `set_intact_state()` shows `Board_Intact` and hides `Board_Half_Left`, `Board_Half_Right`, `Splinter_1..6`; `trigger_break()` flips visibility, plays embedded `Break` animation (`0.60 s`, `LOOP_NONE`), and `queue_free()`s after `0.65 s`. Used by **Board Smash**, **Wide Split**, and **Torso Twist**. |

> **Asset Sourcing Policy:** Every 3D asset bundled in the final build is either generated (`Zeno_WithTexture.glb`, `KarateBoard.glb`) or sourced from external asset stores such as Sketchfab (`Environment.glb`). The GA3 reconstructed water bottle (`ga3/scan_fitted.glb`) is strictly course documentation and is **not** loaded or shipped in the Godot build.
