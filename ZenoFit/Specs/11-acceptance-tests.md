# Acceptance Tests

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 10. Acceptance tests

| ID | Given / When / Then |
|---|---|
| AT-01 | **Given** calibration with `R_f,L = 0.60`, `k = 0.85`, **when** a Forward Reach target is spawned for the left hand, **then** its BodyFrame `z = 0.51 m ± 0.001`. |
| AT-02 | **Given** `L = 0.60`, `k = 0.85`, `θ = 60°`, **when** a Side Raise target is computed, **then** `x_offset = 0.442 ± 0.001` and `y_offset = −0.255 ± 0.001`. |
| AT-03 | **Given** θ_max = 60°, **when** a spawner requests θ = 75°, **then** θ is clamped to ≤ 60° (and never above 70° even if configured higher). |
| AT-04 | **Given** an obstacle sphere at a candidate position, **when** the spawner picks a position, **then** the target is not within `r_ex + targetRadius` of the obstacle. |
| AT-05 | **Given** BPM = 60, **then** `interval = 1.0 s`; **given** BPM = 75, **then** `0.8 s`. |
| AT-06 | **Given** the case-study accuracy sequence (87.5 %, 75 %, 50 %), **then** tempo goes 60 → 65 → 65 → 60. |
| AT-07 | **Given** `lifetime = 2.0 s`, hit at 0.5 s, **then** points = 137. |
| AT-08 | **Given** the 5-target case study, **then** total = 515 and accuracy = 80 %. |
| AT-09 | **Given** both hands within 0.15 m of `LapPoint` for 2.0 s, **then** the game pauses. With one hand outside, it does not pause. |
| AT-10 | **Given** `|Δx| = 0.22 m` for 0.6 s, **then** a lean warning/pause is shown; at 0.12 m, nothing happens. |
| AT-11 | **Given** right hand disabled in calibration, **then** only left-hand targets spawn and the right controller is ignored. |
| AT-12 | **Given** Seated Boxing with `v_solid = 0.30`, hand speed 0.4 m/s → solid hit; 0.2 m/s → light hit; both score. |
| AT-13 | **Given** a fast hand movement across a small target in one frame, **then** the segment-distance test registers a hit (no tunnelling). |
| AT-14 | **Given** the user presses *Menu* during any round, **then** play pauses within 1 frame and timers/beat clock stop. |
| AT-15 | **Given** the app is quit and reopened, **then** the saved calibration profile loads and `sessions.json` still contains previous sessions. |
| AT-16 | **Given** a headset recenter event during gameplay, **then** the game pauses and requests seat re-confirmation (`GP-CAL-06`). |
| AT-17 | *(Needs real headset)* **Given** a full session on Quest 2, **then** FPS stays at 72 with no sustained drops. |
| AT-18 | *(Needs real headset)* **Given** a 10-minute session with healthy seated testers, **then** the SSQ score and enjoyment ratings are recorded for review. |

AT-01 … AT-16 can be automated or verified with simulators. AT-17 and AT-18 **require hardware**.
