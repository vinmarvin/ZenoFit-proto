# Acceptance Tests

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files** (see `00-gameplay-overview.md`).
> Each test has an ID. Tests marked *(Needs real headset)* cannot be passed in a simulator. All other tests should be automated (EditMode / unit tests in either engine) so the **Unity and Godot builds can be checked against the same numbers**.

---

## 10. Acceptance tests

| ID | Given / When / Then |
|---|---|
| AT-01 | **Given** `R_f = 0.60`, `k = 0.85`, `z0 = 1.5`, `t_lead = 1.0`, **when** an asteroid is spawned (§6.1), **then** `z_hit = 0.51 ± 0.001` and `v_a = 0.99 ± 0.001`. For Rani (`R_f,R = 0.42`, `k = 0.75`): `v_R = 1.185 ± 0.001`. |
| AT-02 | **Given** `L_arm = 0.60`, `k = 0.85`, `θ = 60°`, **when** a Glider Pilot hand target is computed (§6.3), **then** `x = 0.442 ± 0.001` and `y = −0.255 ± 0.001`. **Given** left `y = 0`, right `y = 0.10`, span 1.00 → `roll = 5.7° ± 0.1`, `v_lat = 0.57 ± 0.01`. |
| AT-03 | **Given** `L_arm = 0.60`, `k = 0.85`, `φ = 45°`, shoulder `y = 0.12` **when** a fruit is placed (§6.2), **then** `y = 0.481 ± 0.002`, `z = 0.361 ± 0.002`, gaze elevation `32.6° ± 0.2`; if gaze > 45° the spawner reduces `φ`. |
| AT-04 | **Given** an obstacle sphere at a candidate position, **when** the spawner picks a position, **then** the target is not within `r_ex + targetRadius` of it (§4.5). |
| AT-05 | **Given** BPM 60 → interval `1.0 s`; BPM 75 → `0.8 s` (`02` §6.B). |
| AT-06 | **Given** window accuracies 87.5 %, 75 %, 50 %, **then** tempo goes 60 → 65 → 65 → 60. |
| AT-07 | **Given** `lifetime = 2.0 s`, hit at 0.5 s, **then** base points = 137 (§7.1). |
| AT-08 | **Given** the 5-target case study (§7.1), **then** base total = 515 and accuracy = 80 %. With combo (§7.5) the round score = 526. |
| AT-09 | **Given** both hands within 0.15 m of `LapPoint` for 2.0 s, **then** the game pauses. With one hand outside, it does not. |
| AT-10 | **Given** a Level A mechanic and `|Δx| = 0.22 m` for 0.6 s, **then** a lean warning shows; at 0.12 m nothing happens. For §6.10 the threshold is `min(Δx_max + 0.05, 0.30)`. |
| AT-11 | **Given** the right hand disabled in calibration, **then** only left-hand targets spawn and the right controller is ignored. |
| AT-12 | **Given** `v_solid = 0.30`, hand speed 0.4 m/s → solid hit; 0.2 m/s → light hit; both score. |
| AT-13 | **Given** a fast hand movement across a small target in one frame, **then** the segment-distance test registers a hit (no tunnelling, `02` §6.C). |
| AT-14 | **Given** the user presses *Menu* during any round, **then** play pauses within 1 frame and the beat clock/timers stop. |
| AT-15 | **Given** the app is quit and reopened, **then** the saved profile loads and the sessions history still exists. A returning user reaches the first target in ≤ 15 s of calibration time (`GP-CAL-11`). |
| AT-16 | **Given** a headset recenter event during a round, **then** the game pauses and asks for seat re-confirmation (`GP-CAL-06`). |
| AT-17 | *(Needs real headset)* **Given** a full 3-minute session on Quest 2, **then** FPS stays at 72 with no sustained drops. |
| AT-18 | *(Needs real headset)* **Given** a 3-minute session with seated testers, **then** the SSQ score and enjoyment ratings are recorded. |
| AT-19 | **Given** `ψ_max,L = 50°`, `k = 0.85`, **then** the turret target yaw = `42.5°`, `x = 1.013 ± 0.002`, `z = 1.106 ± 0.002` at `D = 1.5`; aim `40°` locks (error 2.5° ≤ 6°) (§6.4). |
| AT-20 | **Given** `R_f = 0.60`, `k = 0.75`, `D = 1.0`, `N = 7`, **then** `g = 0.476 ± 0.001`. For `R_f,R = 0.42`: `g = 0.866 ± 0.001` (§6.5). |
| AT-21 | **Given** `t_hold = 1.5 s`, `T_full = 2.0 s`, **then** `charge = 0.75` and points = 75 (§6.6). Two-hand plane uses `min(R_f,L, R_f,R)`. |
| AT-22 | **Given** `f_target = 0.75 Hz`, measured 0.90 Hz → in band (20 %); 1.00 Hz → out of band (33 %). `v = 2π × 0.18 × 0.75 = 0.848 ± 0.001` (§6.7). |
| AT-23 | **Given** head speed 90°/s during a scan, **then** the dwell timer pauses (does not reset) and a "slower" cue shows (§6.8). |
| AT-24 | **Given** `τ = 0.20 s`, `Δt = 1/72`, **then** per-frame gap closure = `6.7 % ± 0.1`; steady lag at 0.5 m/s = `0.10 m`. For `L_arm = 0.52`: `d_curl = 0.182`, `d_ext = 0.442` (§6.9). |
| AT-25 | **Given** `Δx_max,R = 0.28`, `k = 0.85`, **then** gap centre `g = 0.238 ± 0.001` (≤ 0.25 cap); head at `0.30` → fail, at `0.22` → success (§6.10). |
| AT-26 | **Given** a Score Attack draw, **then** it has 5 distinct mechanics with at least one from each group, and with No-trunk mode on it contains no Level B mechanic. |
| AT-27 | **Given** `streak_before = 10`, base 137, **then** hit points = 205 (§7.5). |
| AT-28 | **Given** the user declines the stable-chair confirmation, **then** the Level B round is skipped and another Level A mechanic is substituted. |

AT-01 … AT-16 and AT-19 … AT-28 can be automated or verified with simulators. AT-17 and AT-18 **require hardware**.

**Parity rule for the two-engine plan:** AT-01 … AT-28 (except 17–18) must produce the **same numbers** in the Unity build and in the Godot build.
