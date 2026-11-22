# ZenoFit — Seated VR Zen Dojo Arcade: AI Reconstruction Spec Pack (Godot 4.7)

> **Version:** 0.4 (Aligned for Week 14 Playtest) · **Date:** 2026-11-22 · **Engine:** Godot 4.7 Only
> **Scope:** This pack is the **Single Source of Truth** for AI coding assistants revising `godot/`. If code and spec disagree, update the code to match v0.4 (or flag an explicit spec question).

**Legend used in every file**

| Tag | Meaning |
|---|---|
| **[S]** | From source PDFs or empirical research (WHO, SKI 2023, Xu et al. 2020, Flatlandsmo 2023, Moffitt 2024). |
| **[D]** | Locked ZenoFit team design decision (PM, Architect, UI, UX Research). |
| **[P]** | Sensible default tunable (`Resource` / `@export`). Tune during Week 14 playtesting. |
| **[V]** | Vendor/version-dependent. Verify on real **PICO 4 Ultra** and **Meta Quest 3**. |
| **MUST / SHOULD / MAY** | Requirement strength. |

---

## 1. Files in this pack

| File | Read it when you need to... |
|---|---|
| `../AGENTS.md` | Hard AI build rules, render budget, anti-cheat rules, and test command. |
| `00-README.md` (this file) | Scope, locked decisions (`D-01`–`D-19`), risks, and AI coding rules. |
| `03-godot-build.md` | **Active Godot 4.7 build guide:** multi-platform PICO 4 Ultra & Meta Quest 3, OpenXR Hand Tracking + Controller hybrid setup, render budget, and SpecSpace traps. |
| `04-workspace-and-antigravity.md` | Repository layout (`berkas/`, `godot/`, `asset/`) and copy-paste AI revision tasks for the 2-week Week 14 sprint. |
| `01-survey-analysis.md` | Survey findings (`N = 8`, anonymized in `berkas/Ideation/Jaras Pengguna.csv`) and design implications. |
| `01-techstack.md` / `02-quest-config.md` | **[DEPRECATED — Unity removed.]** Kept for historical reference only. Use `03-godot-build.md`. |
| `00-gameplay-overview.md` | §1 goals · §2 Player Flow (Main Menu, Routine Picker, Warm-Up) · §5 Score Attack & 3 Routines · §6 Zen Dojo 10-mechanic table · §11 Week 14 sprint plan · §12 out of scope. |
| `01-body-frame-and-calibration.md` | §3 BodyFrame · §4 calibration (base steps, quick seat check `<= 10 s`, chair check, Level B modules). |
| `02-targets-and-hit-detection.md` | §6.A shared rules · §6.B adaptive tempo · §6.C segment hit detection · **§6.D Anti-Raycast & Anti-Cheat rules**. |
| `03-m01` … `12-m10` | Individual specs for all 10 Zen Dojo mechanics (`M01`–`M10`), including v0.4 Dojo reskin + anti-cheat fixes. |
| `13-scoring-and-score-attack.md` | §7 scoring, combo (`1.0x–2.0x`), **Dojo Mastery Rank (`C/B/A/S/Zen Master`) + Personal Best** (no belt progression), Level A vs. B scoring rule. |
| `14-safety.md` | §8 safety monitors (Hand-tracking lap auto-pause fallback, lean warning, rest reminder, No-Trunk mode, scapular plane). |
| `15-feedback-and-ui.md` | §9 hybrid haptics + **Dojo Audio/Visual Arcade Juice** (for controller-free Hand Tracking), UI screens (`Play/Settings/Credits/Quit`, Routine Picker), Zeno mascot limits. |
| `16-acceptance-tests.md` | §10 automated acceptance tests (`AT-01`–`AT-28` preserved + **`AT-29`–`AT-35`** for anti-cheat, 3 Routines, and Rank/PB). |

---

## 2. Product summary

**ZenoFit** is a standalone **seated upper-body VR Arcade Score Attack game** set inside a calm **Zen Dojo**, designed for **desk-working university students, gamers, and developers ("lazy couch geeks")** on **PICO 4 Ultra** and **Meta Quest 2 / 3 / 3S**. **[D]**

- **Core vibe [D]:** **Zen Mastery Arcade** — tranquil Japanese dojo visual framing (tatami, shoji, wood pillars acting as a static anti-cybersickness reference) paired with fast, rhythmic, combo-driven `30 s` arcade rounds, **Dojo Mastery Ranks (`C / B / A / S / Zen Master`)**, and **Personal Best** tracking.
- **10 Core Mechanics for Week 14 [D]:** All 10 existing mechanics (`M01`–`M10`) are reskinned to the Zen Dojo theme and upgraded with strict anti-cheat/anti-raycast checks so both **Hand Tracking** and **Handheld Controllers** require real upper-body exercise. *(New mechanics like `M11 Dojo Gate Opener / Cactus Arms`, `M12 Rei Breath`, `M13 Ink Spiral` are deferred to Post-Week 14 stretch scope to protect the 2-week deadline.)*
- **3 Routines [D]:** *Full Upper-Body Reset*, *Arms & Shoulders*, and *Back & Posture* (`3 min` Quick default; `6 min` / `10 min` Extended with mid-session Passthrough breather).
- **Accessibility principles retained [S]:** 100% seated upper-body only, calibrated comfortable reach (`<= 85%`), one-hand mode, No-Trunk mode, stop at any time, zero unintended locomotion, **not a medical device**.

---

## 3. Locked Decision Log (v0.4)

| ID | Decision | Status |
|---|---|---|
| D-01 | Single engine: **Godot 4.7+ (`GDScript`, `gl_compatibility`)** in `godot/`. Unity build deleted (`1dbc35c`). | Locked **[D]** |
| D-02 | XR API: **OpenXR** (`Reference Space = Local / Seated`) + Godot OpenXR Vendors plugin. No vendor SDK calls outside `autoload/platform.gd`. | Locked **[D]** |
| D-03 | Input: **Hybrid OpenXR Hand Tracking (primary) + Handheld Controller (fallback)**. **Zero raycasting during `ROUND_PLAY`** (`GP-ANTI-CHEAT-01`). | Locked **[D]** |
| D-04 | Target platforms: **PICO 4 Ultra** & **Meta Quest 2 / 3 / 3S** (+ Linux Desktop Simulator). Render budget targets 72–90 FPS across all three. | Locked **[D]** |
| D-05 | Tracking origin: **Local (seated)**; gameplay positions computed strictly in chest-anchored `BodyFrame` (`SpecSpace` -> Godot via `core/spec_space.gd`). | Locked **[S][D]** |
| D-06 | Passthrough via `Platform.set_passthrough()` (alpha blend) with calm Zen Dojo fallback scene if unsupported. | Locked **[D]** |
| D-07 | Local JSON persistence only (`user://`). No network permission, no cloud leaderboards, no analytics. | Locked **[S][D]** |
| D-08 | Real-device validation on PICO 4 Ultra and Meta Quest 3 is mandatory for Week 12 profiling and Week 14 user evaluation. | Locked **[D]** |
| D-09 | Theme & Mascot: **Zen Dojo** (Japanese tranquil dojo) + **Zeno** (`Floating Mascots.glb`). All 10 mechanics reskinned to Dojo names. | Locked **[D]** |
| D-10 | Primary audience: **desk-working students, gamers, and developers ("lazy couch geeks")**; lower-body mobility accessibility kept via *curb-cut effect*. | Locked **[D]** |
| D-11 | Week 14 scope: **10 existing mechanics (`M01`–`M10`) fully fixed & reskinned** (no extra mechanics before Week 14 playtest). | Locked **[D]** |
| D-12 | Gameplay style: **Arcade Score Attack** (`30 s` rounds, combo `1.0x–2.0x`, **Dojo Mastery Rank `C/B/A/S/Zen Master` + Personal Best**). **No belt progression.** | Locked **[D]** |
| D-13 | Safety levels: **A** (arms only, speed bonus allowed) and **B** (trunk/neck, **smoothness/precision bonus ONLY**, stable-chair gate + No-Trunk mode). | Locked **[D]** |
| D-14 | Routine Picker: **3 Upper-Body Routines** (*Full Upper-Body Reset*, *Arms & Shoulders*, *Back & Posture*) + `3 min` (default) / `6 min` / `10 min` durations + optional `15–20 s` Warm-Up (Xu et al. 2020). | Locked **[D]** |
| D-15 | Main Menu buttons: **`Play`, `Settings`, `Credits`, `Quit`** (`get_tree().quit()`). | Locked **[D]** |
| D-16 | Feedback without haptics: Spatial **Dojo Audio SFX** (with combo pitch escalation) + lightweight **3D particle burst & floating score text** mandatory for Hand Tracking mode. | Locked **[D]** |
| D-17 | Render budget: Total <= 200k–350k tris, <= 120 draw calls, max 1 `DirectionalLight3D` (no real-time room shadows), textures <= 2048/1024, `ETC2/ASTC`. | Locked **[D]** |
| D-18 | Non-medical wording: Never use clinical terms like *"Sores"* or claim eye/pain treatment. | Locked **[S][D]** |
| D-19 | Off-headset break reminders, foot trackers, eye tracking, HR sensors, and cloud profiles remain **out of scope**. | Locked **[D]** |

---

## 4. Rules for AI coding assistants (read before editing `godot/`)

1. Read `../AGENTS.md`, `00-README.md`, `00-gameplay-overview.md`, `03-godot-build.md`, and the target mechanic/subsystem file before modifying code.
2. **Never break existing acceptance tests (`AT-01`–`AT-28`)** when adding v0.4 fixes (`AT-29`–`AT-35`). Run the headless test suite after every slice.
3. **Platform calls live ONLY in `godot/autoload/platform.gd`.** Keep OpenXR standard so both PICO 4 Ultra and Meta Quest 3 work from one codebase.
4. **No raycasting during `ROUND_PLAY`.** Enforce all anti-cheat checks in `core/mechanics_math.gd` + `mechanics/mXX/*.gd`.
5. **No locomotion.** Never move, rotate, or scale `XROrigin3D` during gameplay. Never roll the world camera.
6. **Never place a target outside `k <= 0.85` calibrated reach or inside obstacle exclusion zones.** Use the **scapular plane ($15^\circ\text{–}30^\circ$ forward)** for wide-arm mechanics (`M03`) so optical hand tracking stays inside camera FoV.
7. **Pure maths in `godot/core/`**; convert coordinates and yaw ONLY through `godot/core/spec_space.gd`.
8. **Respect the mobile VR render budget (D-17)**—never enable SSAO, SSR, volumetric fog, or real-time room shadows.
9. **No health/medical claims** in UI text, code, or docs (*"Not a medical device"*).
10. Work in small, verifiable slices (see `04-workspace-and-antigravity.md` §4).

---

## 5. Changelog

| Date | Change |
|---|---|
| 2026-11-11 | v0.1 initial draft (Quest + PICO, single gameplay file). |
| 2026-11-12 | v0.2 Meta Quest only; gameplay split into files with Tunables + Open questions. |
| 2026-11-15 | v0.3 desk-gamer audience; 10 mechanics; Score Attack; safety levels A/B; Godot parallel build added. |
| 2026-11-22 | **v0.4 Zen Dojo Arcade Revision:** Godot 4.7-only (Unity deleted); repo reorganized (`berkas/`, `godot/`, `asset/`); PICO 4 Ultra + Meta Quest 3 multi-platform + render budget; Hybrid Hand Tracking + Controller fallback; strict Anti-Raycast & Anti-Cheat rules (`AT-29`–`AT-35`); 3 Routines + `3/6/10 min` + Main Menu (`Play/Settings/Credits/Quit`); Dojo Mastery Rank + Personal Best (no belt progression); Dojo Audio/Visual Juice for controller-free play; 2-week Week 14 sprint scope locked to 10 existing mechanics. |
