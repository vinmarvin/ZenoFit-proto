# Gameplay Overview

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 0. File index

| File | Contains (global section numbers) |
|---|---|
| `00-gameplay-overview.md` | §1 goals, §2 app flow, §5 session/difficulty/hand mode, §11 build order, §12 out of scope |
| `01-body-frame-and-calibration.md` | §3 BodyFrame, §4 calibration (steps, comfort envelope, obstacles, saved data) |
| `02-targets-and-hit-detection.md` | §6.0 shared exercise rules, §6.4 adaptive tempo, §6.7 hit detection |
| `03-ex-forward-arm-reach.md` | §6.1 Forward Arm Reach |
| `04-ex-alternating-arm-reach.md` | §6.2 Alternating Arm Reach |
| `05-ex-side-arm-raise.md` | §6.3 Side Arm Raise |
| `06-ex-forward-press.md` | §6.5 Forward Press |
| `07-ex-seated-boxing.md` | §6.6 Seated Boxing |
| `08-scoring-and-results.md` | §7 scoring, results, progress tracking |
| `09-safety.md` | §8 safety system |
| `10-feedback-and-ui.md` | §9 haptics, audio, visual style, settings |
| `11-acceptance-tests.md` | §10 acceptance tests |

**How to make the spec more specific:** each exercise file ends with a *Tunables* table (edit the "Your value" column) and an *Open questions* list. Answer those, and the defaults tagged **[P]** become decisions.

---

## 1. Experience goals

| # | Goal | Source |
|---|---|---|
| G1 | The user is **seated the whole time**; nothing requires standing, squatting, or leg movement. | [S] |
| G2 | Every target is inside the user's **own comfortable reach**. | [S] |
| G3 | Scoring depends only on **arm accuracy and rhythm**. | [S] |
| G4 | **Zero unintended locomotion**: the world never moves the user. | [S] |
| G5 | The user can **pause or stop at any time**, and can use **one hand or two**. | [S] |
| G6 | Calm visuals, readable UI, soft audio. | [S] |

---

## 2. App flow (state machine)

```
Boot → MainMenu → Calibration → ExerciseSelect → Gameplay → Results
           ▲                           ▲             │  ▲        │
           │                           └─────────────┘  │        │
           └──────────────── (back / finish) ──────────┴────────┘
Gameplay ⇄ Paused  (from any state in Gameplay)
```

| State | Entry | Exit |
|---|---|---|
| **Boot** | App start. Init platform + XR rig + load saved profile. | Rig ready → MainMenu. |
| **MainMenu** | After Boot / Results. Buttons: *Start*, *Recalibrate*, *Settings*, *Quit*. | *Start* → Calibration if no valid profile, otherwise ExerciseSelect. |
| **Calibration** | First run, *Recalibrate*, or recenter event. | Success → save profile → ExerciseSelect. |
| **ExerciseSelect** | After Calibration. Choose exercise, difficulty, hand mode (§5.2). | *Play* → Gameplay. |
| **Gameplay** | Round runs (§6, §7). | Round complete or *Stop* → Results. |
| **Paused** | Pause button, auto-pause, rest reminder, lean warning. | *Resume* (with 3-2-1 countdown) or *Stop*. |
| **Results** | After Gameplay. | *Again* / *Change exercise* / *Menu*. |

`GP-FLOW-01` The state machine MUST be a single class (`GameFlow`) with explicit transitions; scenes are loaded additively over `00_Boot`.
`GP-FLOW-02` Resume MUST include a short countdown **[P]** (3 s) so the user can get back into position before targets spawn.

---

## 5. Exercise selection, difficulty, hand mode

### 5.1 Common session structure **[P]**

| Item | Default |
|---|---|
| Targets per round | 20 |
| Rounds per session | 3 |
| Rest between rounds | 30 s (user can end rest early) |
| Rest reminder | every **8 min** (range 7–10 **[S]**) |
| Target radius (hit sphere) | per preset (below) |
| Target lifetime | `L` beats (per preset) before it counts as a miss |

### 5.2 Hand mode `GP-HAND-01` **[S]**
`Both hands` · `Left only` · `Right only`. Left-only / Right-only means all targets are for that hand and the other controller is ignored. Disabled hands (§4.2 steps 4–5 skipped) force one-hand mode.

### 5.3 Difficulty presets **[P]**

| Parameter | Gentle | Standard | Active |
|---|---|---|---|
| Reach factor `k` | 0.60 | 0.75 | 0.85 (max **[S]**) |
| Target radius | 0.12 m | 0.10 m | 0.08 m |
| Start tempo | 50 BPM | **60 BPM [S]** | 70 BPM |
| Max tempo | 70 BPM | 80 BPM | 90 BPM |
| Target lifetime `L` | 3 beats | 2 beats | 2 beats |

`GP-DIFF-01` Difficulty MUST be adjustable via **target distance (k), target size, and tempo** only. **[S]** (Adaptive Difficulty)
`GP-DIFF-02` Tempo only **increases** when accuracy is stable (§6.4).

---

## 11. Suggested build order (maps to the 8-week plan **[S]**)

| Week | Build | Verifiable without headset? |
|---|---|---|
| 1 | Project setup, rig, `IPlatformServices`, EditorSim, builds for both profiles. | Yes (build only) |
| 2 | Controller tracking, HandTip, segment hit detection, BodyFrame. | Mostly (simulator) |
| 3 | Calibration flow + JSON save/load + obstacle zones. | Logic yes; feel no |
| 4 | Forward Reach, Alternating Reach, Forward Press (3 exercises). | Logic yes |
| 5 | Side Arm Raise, Seated Boxing. | Logic yes |
| 6 | UI, scoring, results, safety system, settings. | Mostly |
| 7 | Functional + usability testing. | **Needs headset** |
| 8 | Fixes, documentation, demo build. | **Needs headset** |

---

## 12. Out of scope (do not build) **[S]**
Hand tracking · heart-rate sensors · biomechanics analysis · cloud storage · leaderboards/online · virtual instructor · Shoulder Rolls, Elbow Flexion, Seated Swimming, Biceps Curl, Seated Row · clinician dashboard.
