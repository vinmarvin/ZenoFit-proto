# 03 — Spatial UI (`UI.pdf`), FoV-Safe Zeno Mascot & Integrated Assets

> **Sources of Truth:** `berkas/UI.pdf`, `CREDITS.md`, `godot/ui/dojo_panel_3d.gd`, `godot/ui/world_ui.gd`, `godot/mascot/floating_mascot_coach.gd`, `godot/core/dojo_environment_loader.gd`, `godot/mechanics/karate_board_prop.gd`.

---

## 1. Dark-Sage Glassmorphism Design System (`DojoPanel3D`)

All 3D VR menus render high-DPI Godot `Control` trees inside a transparent `SubViewport` mapped onto an unshaded double-sided `QuadMesh` (`SHADOW_CASTING_SETTING_OFF`), supporting exact ray-to-UV intersection (`DojoPanel3D.intersect_ray`, valid range `0.05 < t <= 6.0 m`) even under scaled `ZenoWorldUI` transforms, with responsive inner padding for compact HUD heights (`pad_x/pad_y`: `20/8 px` for `viewport_px.y <= 140`, `24/14 px` for `<= 240`, `28/22 px` otherwise).

| Token Constant | Color (`RGBA` / `RGB`) | Purpose |
| :--- | :--- | :--- |
| `COL_BG_GLASS` | `(0.08, 0.12, 0.10, 0.86)` | Translucent dark-sage glass panel background (`corner_radius = 24`) |
| `COL_BORDER` | `(0.30, 0.44, 0.37, 0.72)` | `2 px` frosted glass rim |
| `COL_CARD_BG` | `(0.11, 0.16, 0.13, 0.84)` | Elevated card / exercise tile fill (`corner_radius = 16`) |
| `COL_CARD_BORDER` | `(0.28, 0.42, 0.35, 0.56)` | Subtle `1 px` card outline |
| `COL_PRIMARY` | `(0.76, 0.87, 0.75, 0.96)` | Sage-mint primary CTA fill |
| `COL_PRIMARY_TEXT` | `(0.07, 0.12, 0.09)` | High-contrast dark ink text inside primary buttons |
| `COL_SELECTED` | `(0.20, 0.48, 0.43, 0.92)` | Active filter / setting pill highlight |
| `COL_DESTRUCTIVE` | `(0.38, 0.17, 0.19, 0.88)` | End session / exit / reset actions |
| `COL_DESTRUCTIVE_BORDER` | `(0.74, 0.36, 0.38, 0.78)` | Destructive button outline |
| `COL_TEXT_MAIN` | `(0.94, 0.97, 0.95)` | High-contrast primary copy |
| `COL_TEXT_MUTED` | `(0.68, 0.77, 0.72)` | Secondary metadata & subtitles |
| `COL_ACCENT_TEAL` | `(0.45, 0.82, 0.74)` | Section eyebrows & category pills |

---

## 2. 11-Screen Spatial Flow & HUD Ergonomics (`ZenoWorldUI`)

### 2.1 Complete Screen & State Flow (`ZenoEnums.AppState`)
1. `WELCOME` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) — Two-column onboarding hero: left branding card + non-medical disclaimer (`"Preventive wellness game • Not a medical device."`); right `Seated Comfort Check` (`SEATED HEIGHT`, `Input Mode` switch, `Calibrate Reach`, `Recenter View`, `Continue to Dojo >`).
2. `MAIN_MENU` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`, leaving Zeno clear on the right) — Left greeting + `RECENT FLOW` tile (`sessions_count`, `best_score`, `best_rank`) + `Credits` & `Recenter`; right `Start Quick Break • 3 Min Mix` hero CTA + `2×2` grid (`Exercise Library` showing dynamic count of `11` seated movements, `Tutorial`, `Settings`, `Exit Experience`).
3. `EXERCISE_SELECT` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) — Category filter tabs (`All Exercises`, `Active`, `Mobility`, `Posture`) + adaptive grid (`4` columns when `list.size() >= 4`, compact density mode when `list.size() > 8` so all `11` cards fit without overflow; zero `M01..M10` internal IDs).
4. `EXERCISE_PREVIEW` (`1.38 × 0.80 m`, `1180 × 684 px`, centered `x = 0.0`) — Left translucent live-coach frame around 3D Zeno demonstrating the exact exercise; right 3 numbered `HOW TO MOVE` steps, `DURATION` (`45 sec` + input mode) & `COMFORT` tiles, **optional dumbbell guidance card** (`Shoulder Press`, `Bicep Curl`, `Arm Circles` only), and `Start Exercise >` CTA.
5. `CALIBRATION` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) — 3-step guided setup (`1/3 Seated Posture`, `2/3 Comfortable Reach (Left)` / `(Right)`, `3/3 Rest & Lap Zone`), progress bar, `Skip Step`, `Confirm Step`, and `< Back`.
6. `ROUND_INTRO / ROUND_PLAY / ROUND_OUTRO` — Uncluttered **Compact Top HUD** (`1.14 × 0.16 m`, `1020 × 144 px`, `y = +0.45 m`, `z = hud_dist + 0.14 m`) showing exercise title, live subtitle (body area, `Round X of Y`, or `active_mechanic.get_set_display_text()` for two-set exercises), score/streak, countdown, `Pause` button, and progress bar; paired with **Compact Bottom Cue Bar** (`0.90 × 0.095 m`, `820 × 86 px`, `y = -0.45 m`).
7. `PAUSED` (`0.96 × 0.72 m`, `920 × 690 px`, `x = -0.08 m`) — Centered overlay showing `SESSION PAUSED` badge, `"Take your time."` / `"Resuming in N..."`, pause reason subtitle, 3 live metric tiles (`EXERCISE`, `TIME LEFT`, `CURRENT SCORE`), primary CTA (`Switch Input Mode & Resume` on `INPUT_LOST`, else `Resume Workout`), `2×2` action grid (`Restart Exercise`, `Settings`, `Recenter View`, `Main Menu`), and `Exit Experience`; active `arena_root` props automatically hide while paused.
8. `RESULTS` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) — `SESSION COMPLETE` header, `"Nice work."` (`• New Personal Best!` if earned), 3 metric tiles (`SCORE`, `SESSION TIME`, `ACCURACY & RANK`), `"Areas moved"` card, and actions (`Repeat`, `Choose Another`, `Main Menu`).
9. `SETTINGS` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) — 4 left-sidebar tabs: `Comfort` (Difficulty, Active Hands, `Recalibrate Seated Comfort`, `Reset Saved Data`), `Input & Haptics` (`Input Source`, `Controller Haptics` ON/OFF), `Audio` (Master Sound Volume progress bar + `Volume -/+` `±15%`), `Display & HUD` (`Panel Distance` `±0.15 m`, `Panel Scale` `±0.05x`). (`rest_reminder_minutes` `8.0 min` and `haptic_intensity` `1.0` exist in `settings.json` defaults without dedicated Settings buttons yet.)
10. `TUTORIAL` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) — Paginated 3-page guide (`Point & Select`, `Move Within Comfort`, `Pause Anytime`) with `Previous` / `Next >` / `Done`.
11. `CREDITS` (`1.38 × 0.80 m`, `1180 × 684 px`, `x = -0.20 m`) & `EXIT_CONFIRM` (`0.84 × 0.56 m`, `760 × 506 px`, `x = -0.06 m`) — Credits naming **Team ZenoFit — Group 4 (Lebah Ganteng)**, **Institut Teknologi Sepuluh Nopember (ITS)**, `"Japanese Traditional Room"` by **`jrevel`** (CC BY 4.0 / Sketchfab), `Zeno Mascot & Karate Board` (`Claude Sonnet 5.5`), and non-medical disclaimer; dedicated exit modal with `Stay in Dojo` and `Exit Experience`.

### 2.2 Ergonomics Clamping & Zero-Debug VR Rules
- **Configurable HUD Ergonomics (`GameFlow.adjust_hud_distance`, `adjust_hud_scale`):**
  - `hud_distance_m`: clamped `[1.30, 2.20] m`, default `1.65 m` (`±0.15 m` Settings buttons in `ZenoWorldUI`).
  - `hud_scale`: clamped `[0.85, 1.20]x`, default `1.00x` (`±0.05x` Settings buttons).
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
    - Menus (`WELCOME`, `MAIN_MENU`, etc.): `z_menu = clamp(hud_dist + 0.08, 1.62, 2.24)`, `mx = min(0.72, z_menu * tan(23°))`, `scale = 0.140`, `facing = -22°` (clear of panel right edge).
  - Guarantees Zeno never sits cropped outside VR headset lenses (verified `<= 24°` across 12 state×distance combinations in `MASCOT-FOV`).
- **Live 11-Exercise Demonstrations (`_animate_joints`):** Animates distinct procedural joint trajectories for every `ExerciseId` `1..11` (including `SHOULDER_PRESS`, `BICEP_CURL`, `ARM_CIRCLES`, and `LATERAL_RAISE`) during `EXERCISE_PREVIEW`, `ROUND_INTRO`, and `ROUND_PLAY`, plus cheering/sway reactions.
- **High-Five Poke Reaction & Temporary Bubble:** Outside `ROUND_PLAY`, touching within `POKE_RADIUS_M = 0.22 m` triggers happy eyes + bounce + `"High five!"` bubble (`1.8 s`, `0.8 s` cooldown; `WELCOME` `2.6 s`, `RESULTS` `2.5 s`, 5-streak cheer `"Streak x%d!"` `1.5 s`, default helper param `2.0 s`, auto-hidden on `ROUND_PLAY`).

---

## 4. Integrated 3D Assets & Render Budget

| Asset (`godot/assets/`) | Role | Structural / Optimization Rules |
| :--- | :--- | :--- |
| **`Environment.glb`** | Calm Japanese minimalist tatami/shoji room (Sketchfab) | `DojoEnvironmentLoader.load_and_clean_dojo_environment()`: shifts `scene_root` `+0.75 m` Z to center player in room; keeps strictly 6 nodes (`group3`, `group4`, `walls`, `roof`, `group7`, `group8`) and frees 28 stray external pieces (`pCube*`, etc.); sets `CULL_DISABLED`, `roughness >= 0.65`, shadow casting `OFF`. |
| **`Zeno_WithTexture.glb`** | Sole textured rigged mascot (Generated) | Loaded via `FloatingMascotCoach`; `Ground_Ring*` hidden; shadow casting `OFF`. |
| **`KarateBoard.glb`** | Breaking pine karate board (Generated, `604` tris, `0.28 × 0.25 × 0.018 m`) | Loaded via `KarateBoardProp`; attaches emissive hand-cue top/bottom rims (`Mint` left / `Amber` right); `set_intact_state()` shows `Board_Intact` and hides `Board_Half_Left`, `Board_Half_Right`, `Splinter_1..6`; `trigger_break()` flips visibility, plays embedded `Break` animation (`0.60 s`, `LOOP_NONE`), and `queue_free()`s after `0.65 s`. Used by **Board Smash**, **Wide Split**, and **Torso Twist**. |

- **Procedural Geometry Budget:** All runtime-generated geometries (`MechanicalTensionGuide` tubes/beads/rings, `MechanicBase` orbs/boxes/lanterns/dials/VFX, `Main` hand motion trails) strictly enforce `SHADOW_CASTING_SETTING_OFF`.

### Background Music (`godot/assets/audio/`, OGG, imported `loop=true`)
| Track | Plays During | Notes |
| :--- | :--- | :--- |
| **`MainMenu_BGM.ogg`** (`menu`) | `WELCOME`, `MAIN_MENU`, `EXERCISE_SELECT`, `EXERCISE_PREVIEW`, `TUTORIAL`, `CREDITS` | Restarts from the top when returning from Results. |
| **`Workout_Play.ogg`** (`workout_play`) | `SESSION_START`, `ROUND_INTRO`, `ROUND_PLAY`, `ROUND_OUTRO`, `PAUSED` | Continuous across rounds, pause and Settings-from-Pause (never restarts mid-session). |
| **`Workout_Complete.ogg`** (`workout_complete`) | `RESULTS` | Loops for as long as the player stays on the Results screen. |

`SETTINGS`, `EXIT_CONFIRM`, and `CALIBRATION` keep whichever track is already playing (fallback `menu`). Switching cross-fades over `0.8 s`; music volume follows the Settings `Audio` slider (`audio_volume` x `0.55`, `0` = silent).

> **Asset Sourcing Policy:** Every 3D asset bundled in the final build is either generated (`Zeno_WithTexture.glb`, `KarateBoard.glb`) or sourced from external asset stores such as Sketchfab (`Environment.glb`). The GA3 reconstructed water bottle (`ga3/scan_fitted.glb`) is strictly course documentation and is **not** loaded or shipped in the Godot build.
