# Acceptance Tests (v0.4 — AT-01 through AT-35)

> Part of the **ZenoFit AI Reconstruction Spec Pack (Godot 4.7)**. **Section numbers are global across all gameplay files** (`00-gameplay-overview.md`).
> Run all automated tests headlessly via:
> ```bash
> godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
> ```
> **Hard Rule:** `AT-01`–`AT-28` numeric expectations MUST remain intact (68 existing assertions pass) while adding `AT-29`–`AT-35` for v0.4 Anti-Cheat, 3 Routines, and Dojo Mastery Rank / Personal Best.

---

## 10.1 Core & Existing Tests (`AT-01`–`AT-28` — Preserved)

| ID | Given / When / Then |
|---|---|
| SPEC-SPACE | Spec `+0.51 m` forward → Godot `-0.51 m`; Spec `+40°` right yaw → Godot `-40°` (`03-godot-build.md` §2). |
| AT-01 | **Given** `R_f = 0.60`, `k = 0.85`, `z0 = 1.5`, `t_lead = 1.0`, **then** `z_hit = 0.51 ± 0.001` and `v_a = 0.99 ± 0.001`. For Rani (`R_f,R = 0.42`, `k = 0.75`): `v_R = 1.185 ± 0.001` (§6.1). |
| AT-02 | **Given** `L_arm = 0.60`, `k = 0.85`, `θ = 60°`, **then** `x = 0.442 ± 0.001`, `y = -0.255 ± 0.001`. Left `y = 0`, right `y = 0.10`, span `1.00` → `roll = 5.7° ± 0.1`, `v_lat = 0.57 ± 0.01` (§6.3). |
| AT-03 | **Given** `L_arm = 0.60`, `k = 0.85`, `φ = 45°`, shoulder `y = 0.12`, **then** `y = 0.481 ± 0.002`, `z = 0.361 ± 0.002`, gaze `32.6° ± 0.2`; if gaze `> 45°`, reduce `φ` (§6.2). |
| AT-04 | **Given** an obstacle sphere at candidate position, spawner rejects it and resolves outside `r_ex + targetRadius` (§4.5). |
| AT-05 | **Given** BPM `60` → `1.0 s`; BPM `75` → `0.8 s` (`02` §6.B). |
| AT-06 | **Given** window accuracies `87.5%`, `75%`, `50%`, tempo goes `60 → 65 → 65 → 60`. |
| AT-07 | **Given** `lifetime = 2.0 s`, hit at `0.5 s`, base points = `137` (§7.1). |
| AT-08 | **Given** 5-target case study (§7.1), base total = `515`, accuracy = `80%`, combo round score = `526`. |
| AT-09 | **Given** both hands within `0.15 m` of `LapPoint` for `2.0 s`, game pauses; one hand outside does not (§8.1). |
| AT-10 | **Given** Level A & `|Δx| = 0.22 m` for `0.6 s` → lean warning; `0.12 m` → no warning. For `M10`: `min(Δx_max + 0.05, 0.30)` (§8.4). |
| AT-11 | **Given** right hand disabled in calibration → `LEFT_ONLY` forced and right hand ignored. |
| AT-12 | **Given** `v_solid = 0.30`, `0.4 m/s` → solid hit (`+25`); `0.2 m/s` → light hit (`MechanicsMath.m01_is_solid_hit`). |
| AT-13 | **Given** fast hand crossing target in 1 frame → segment-to-sphere hit registers without tunnelling (`02` §6.C). |
| AT-14 | **Given** Pause pressed during any round → `PAUSED` within 1 frame and timers freeze. |
| AT-15 | **Given** restart → saved profile & session history reload; returning user quick seat check completes in 1 confirm (`<= 10 s`). |
| AT-16 | **Given** headset recenter event during a round → pauses and requests seat re-confirmation. |
| AT-17 | *(Needs real PICO 4 Ultra / Meta Quest 3)* Full 3-minute session holds `>= 72 FPS` within render budget (`<= 200k–350k` tris, `<= 120` draw calls). |
| AT-18 | *(Needs real headset)* Week 14 seated evaluation records task completion, IMI enjoyment/usefulness, and MSAQ/SSQ. |
| AT-19 | **Given** `ψ_max,L = 50°`, `k = 0.85` → target yaw `42.5°`, `x = 1.013 ± 0.002`, `z = 1.106 ± 0.002` at `D = 1.5`; aim `40°` locks (`<= 6°`) (§6.4). |
| AT-20 | **Given** `R_f = 0.60`, `k = 0.75`, `D = 1.0`, `N = 7` → `g = 0.476 ± 0.001`; `R_f,R = 0.42` → `g = 0.866 ± 0.001` (§6.5). |
| AT-21 | **Given** `t_hold = 1.5 s`, `T_full = 2.0 s` → `charge = 0.75`, points = `75`; two-hand plane uses `min(R_f,L, R_f,R)` (§6.6). |
| AT-22 | **Given** `f_target = 0.75 Hz`, `0.90 Hz` in-band (`20%`); `1.00 Hz` out-of-band (`33%`); `v = 0.848 ± 0.001` (§6.7). |
| AT-23 | **Given** head speed `90°/s` during `M08` scan → dwell pauses (does not reset) and shows slower cue (§6.8). |
| AT-24 | **Given** `τ = 0.20 s`, `Δt = 1/72` → gap closure `6.7% ± 0.1`, steady lag at `0.5 m/s` = `0.10 m`; `L_arm = 0.52` → `d_curl = 0.182`, `d_ext = 0.442` (§6.9). |
| AT-25 | **Given** `Δx_max,R = 0.28`, `k = 0.85` → gap `g = 0.238 ± 0.001`; head at `0.30` fails, at `0.22` succeeds (§6.10). |
| AT-26 | **Given** `FULL_UPPER_BODY` Score Attack draw → 5 distinct mechanics covering all 3 groups; No-trunk mode excludes all Level B. |
| AT-27 | **Given** `streak_before = 10`, base `137` → combo hit points = `205` (§7.3). |
| AT-28 | **Given** user declines stable-chair confirmation → Level B round is substituted with an unused Level A mechanic. |

---

## 10.2 New v0.4 Tests (`AT-29`–`AT-35` — Anti-Cheat, 3 Routines, Rank & Personal Best)

| ID | Given / When / Then |
|---|---|
| **AT-29** | **Anti-Cheat `M01` (Makiwara Strikes):** A stationary hand (`v_z = 0.0 m/s`) held at `z_hit` MUST NOT register a punch hit; a forward punch with `v_z >= 0.25 m/s` after retracting to `z <= 0.25 m` registers a valid hit (`02` §6.D). |
| **AT-30** | **Anti-Cheat `M03` (Crane Wings):** Hands held close together in front of torso (`span = 0.15 m < 0.70 * calibrated_span`) receive `0` wing-level bonus; hands extended laterally within `θ ± 15°` and `span >= 0.70 * calibrated_span` earn `+10 pts/s` (`05-m03`). |
| **AT-31** | **Anti-Cheat `M04` (Bokken Guard):** Hands at `||mid|| = 0.40 m (> 0.35 m)` OR sliding hands to `aim_yaw = 35°` while `head_yaw = 0°` (`|0 - 35| = 35° > 20°`) MUST NOT lock; `||mid|| <= 0.35 m` and `|head_yaw - aim_yaw| <= 20°` locks normally (`06-m04`). |
| **AT-32** | **Anti-Cheat `M05` & `M06`:** In `M05` (`BOTH_HANDS`), moving only the left hand while right hand stays still does NOT complete a bilateral stroke, and exceeding `2.0 s` stroke timeout resets the stroke; in `M06`, keeping hands past `z_plane` after cooldown does NOT start a new charge until retracted to `<= z_plane - 0.10 m`. |
| **AT-33** | **Anti-Cheat `M07` (Zen Water Wheel):** Oscillating back and forth (`+15° / -15°`) or spinning opposite to the active `CW/CCW` direction yields `0` shield gain; smooth signed-angle rotation matching active direction in-band increases shield energy (`09-m07`). |
| **AT-34** | **Anti-Cheat `M09` & `M10`:** In `M09`, rolling wrist `>= 60°` while `|hand.x - cup.x| = 0.30 m (> 0.14 m)` does NOT accumulate pour time; in `M10`, leaning into the gap while hands dropped below `y_rail - 0.15 m` pauses the wall instead of awarding a dodge. |
| **AT-35** | **3 Routines, Hand-Tracking Lap Fallback, & Dojo Rank / Personal Best:** (a) `ARMS_AND_SHOULDERS` draws 5 `Level A` arm/shoulder mechanics; `BACK_AND_POSTURE` draws 5 mechanics with no consecutive `Level B`. (b) Dropping hands to `y <= -0.25 m` then losing tracking for `2.0 s` triggers `AUTO_PAUSE_LAP`. (c) `93%` accuracy & `26` hits yields `Zen Master (S+)`, `78%` yields `Ronin (A)`, and a higher score updates local `personal_bests` in `SaveService`. |
