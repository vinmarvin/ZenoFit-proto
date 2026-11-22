# ZenoFit — Godot 4.7 Build & AI Reconstruction Rules (v0.4 — Zen Dojo Arcade)

## Single Source of Truth
- Active codebase lives ONLY in `godot/` (Unity build was removed).
- Read `berkas/GodotDocs/MarkdownGuideForAIReconstruction/00-README.md`, `00-gameplay-overview.md`, and `03-godot-build.md` first, then the specific mechanic or subsystem file before editing code.

## Engine, Platform & Render Budget
- **Engine:** Godot 4.7+ (`4.7.2.stable`), **GDScript only**, **Compatibility renderer (`gl_compatibility`)**, OpenXR enabled (`Reference Space = Local / Seated`), Dynamic Foveation Level 2, `ETC2/ASTC` VRAM compression.
- **Multi-Platform Targets:** **PICO 4 Ultra** (`preset.0`) and **Meta Quest 2 / 3 / 3S** (`preset.1`), plus **Linux Desktop Simulator** (`preset.2`). Android package name: `com.zenofit.godot.mockup`.
- **Platform Abstraction:** All XR/vendor calls (haptics, passthrough, recenter, OpenXR hand-tracking bridge) MUST go through `godot/autoload/platform.gd`. Never call Meta-only or PICO-only APIs inside mechanics.
- **Render Budget (72–90 FPS mobile VR):** Total scene <= 200k–350k triangles (Zen Dojo environment <= 120k tris, Zeno mascot ~19.9k tris, active target props < 3k tris each), <= 80–120 draw calls, max 1 `DirectionalLight3D` with NO real-time shadows on static environment, textures <= 2048px (room) / <= 1024px (props), no heavy post-processing (SSAO/SSR/volumetric fog).

## Coordinate Space & Pure Math
- **SpecSpace vs. Godot:** Spec space is `+X` right, `+Y` up, `+Z` FORWARD; positive yaw = turn RIGHT. Godot is `-Z` forward; positive `rotation.y` = turn LEFT. Convert ONLY via `godot/core/spec_space.gd`.
- **Pure Math & Tests:** Keep all formulas in `godot/core/` with headless acceptance tests in `godot/tests/test_acceptance_suite.gd` matching `16-acceptance-tests.md` (`AT-01`..`AT-35`). Run:
  `godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd`

## Gameplay, Input & Anti-Cheat Hard Rules
- **Theme & Vibe:** **Zen Dojo Arcade Score Attack** — calm Japanese dojo static visual reference + snappy arcade scoring, combo multiplier (`1.0x..2.0x`), **Dojo Mastery Rank (`C / B / A / S / Zen Master`)**, and **Personal Best** per Routine (NO belt progression).
- **3 Routines:** `Full Upper-Body Reset`, `Arms & Shoulders`, and `Back & Posture` (durations: `3 min` default Quick Trial; `6 min` / `10 min` Extended with mid-session Passthrough breather).
- **Hybrid Input (Hand Tracking Primary + Controller Fallback):** Support OpenXR `XRHandTracker` (`hand_interaction_ext`: poke, pinch, grasp, wrist roll) AND `XRController3D` fallback seamlessly through `BodyFrame`.
- **NO Raycasting During Gameplay (`GP-ANTI-CHEAT-01`):** Ray pointers are allowed ONLY in menus/UI. During `ROUND_PLAY`, all hits MUST require **Direct 3D Spatial Contact** + mechanic-specific anti-cheat validation (forward velocity & guard return in M01, span/abduction in M03, head-hand yaw cross-check in M04, two-hand stroke + timeout in M05, push-back hysteresis in M06, signed-angle circles in M07, over-cup check in M09, overhead rail hold in M10).
- **Arcade Juice Without Haptics:** When using Hand Tracking (no controller rumble), every hit MUST trigger Dojo spatial audio SFX with combo pitch escalation + lightweight particle burst + floating score text + Zeno cheer on 5x/10x streaks.
- **Level A vs. Level B Scoring Safety:** Level A rewards speed/timeliness; Level B (`M04`, `M08`, `M10`) MUST NEVER reward high speed—reward smoothness/precision only.
- **Zero Unintended Locomotion:** Never move, rotate, or scale `XROrigin3D` during gameplay. Never place targets outside `<= 85%` calibrated reach or inside obstacle exclusion zones.
- **Not a Medical Device:** Never add medical, pain-treatment, or optical eye-relief claims to UI text, code comments, or docs. Never use clinical terms like "Sores" in UI.
