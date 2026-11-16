# Gameplay Overview

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing (Glider Pilot). See the index below.
> Legend: **[S]** from source PDF/research · **[D]** from your ZenoFit draft · **[P]** proposal, tune in testing · **[V]** verify.

---

## 0. File index

| File | Contains (global section numbers) |
|---|---|
| `00-gameplay-overview.md` | §1 goals · §2 app flow · §5 Score Attack session, difficulty, hand mode · §6 mechanics table · §11 build order · §12 out of scope |
| `01-body-frame-and-calibration.md` | §3 BodyFrame · §4 calibration (base steps, module calibrations, obstacles, saved data) |
| `02-targets-and-hit-detection.md` | §6.A shared rules · §6.B adaptive tempo · §6.C hit detection |
| `03-m01-asteroid-brawler.md` | §6.1 Seated Boxing |
| `04-m02-fruit-harvester.md` | §6.2 Overhead Reach |
| `05-m03-glider-pilot.md` | §6.3 Side Arm Raise |
| `06-m04-turret-gunner.md` | §6.4 Trunk Twist |
| `07-m05-cosmic-tug-of-war.md` | §6.5 Seated Row |
| `08-m06-force-blast.md` | §6.6 Forward Press |
| `09-m07-shield-generator-crank.md` | §6.7 Arm Circles |
| `10-m08-recon-scanner.md` | §6.8 Neck Mobility and Far Focus |
| `11-m09-potion-brewer.md` | §6.9 Elbow Flexion and Wrist Pour |
| `12-m10-laser-evader.md` | §6.10 Overhead Reach with Side Bend |
| `13-scoring-and-score-attack.md` | §7 scoring, combo, results, progress |
| `14-safety.md` | §8 safety system, mechanic safety levels |
| `15-feedback-and-ui.md` | §9 haptics, audio, visual style, settings |
| `16-acceptance-tests.md` | §10 acceptance tests |

Research behind these choices: `../research/01-survey-analysis.md`.

**How to make the spec more specific:** every mechanic file ends with a *Tunables* table (edit "Your value") and *Open questions*. Answer those and the **[P]** defaults become decisions.

---

## 1. Experience goals

| # | Goal | Source |
|---|---|---|
| G1 | The user is **seated the whole time**. No standing, squatting, or leg movement. | [D] [S] |
| G2 | Every target is inside the user's **own comfortable range** (reach, twist, lean, neck turn). | [S] |
| G3 | Score depends on **arm accuracy, rhythm, and smoothness**. Never on the lower body. | [S] |
| G4 | **Zero unintended locomotion.** The world never moves the user. | [S] |
| G5 | The user can **pause or stop at any time**, and can use **one hand or two**. | [S] |
| G6 | Calm visuals, readable UI, soft audio. | [S] |
| G7 | A session **fits a work break (about 3 minutes)**. It feels like a score chase, not a workout chore. | [D] |
| G8 | Time from putting the headset on to the first target is short (≤ 30 s for returning users). | [P] from survey |

---

## 2. App flow (state machine)

```
Boot → MainMenu → [Calibration if needed] → SessionStart
        ▲                                        │
        │                                        ▼
        │                      ┌──→ RoundIntro (4 s) → RoundPlay (30 s) → RoundOutro (2 s) ─┐
        │                      └──────────────────────── ×5 rounds ←─────────────────────┘
        └──────────────────────────── Results ←──────────────────────────────────────────
Any Round state ⇄ Paused (menu button, lap rest, rest reminder, lean warning)
```

| State | Entry | Exit |
|---|---|---|
| **Boot** | App start. Init platform, XR rig, load saved profile. | Rig ready → MainMenu. |
| **MainMenu** | After Boot / Results. *Play Score Attack*, *Practice*, *Recalibrate*, *Settings*, *Quit*. | *Play* → Calibration if no valid profile, else quick seat check → SessionStart. |
| **Calibration** | First run, *Recalibrate*, or recenter event. | Success → save profile. |
| **SessionStart** | Pick the 5 mechanics (§5.2). | → RoundIntro. |
| **RoundIntro** | Show mechanic name, one-line instruction, safety note if Level B. | → RoundPlay. |
| **RoundPlay** | 30 s of one mechanic. | Timer end → RoundOutro. |
| **Results** | After round 5 or *Stop*. | *Again* / *Practice* / *Menu*. |
| **Paused** | From any Round state. | *Resume* (3-2-1) or *Stop*. |

`GP-FLOW-01` One `GameFlow` class owns all transitions; scenes load additively over `00_Boot`.
`GP-FLOW-02` Resume includes a 3 s countdown **[P]**.

---

## 5. Score Attack session, difficulty, hand mode

### 5.1 Session structure **[D][P]**

| Item | Default |
|---|---|
| Session | **180 s** = 5 rounds × (4 s intro + 30 s play + 2 s outro) |
| Round | One mechanic, 30 s |
| Rest reminder | every **8 min** of total play (range 7–10 **[S]**) |
| Practice mode | Pick one mechanic, untimed rounds of 30 s, no combo reset between rounds |

### 5.2 Mechanic draw (balanced, random) `GP-SESS-01`

Each mechanic belongs to one body-area group (§6 table). A session picks **5 distinct mechanics** such that:
1. At least **one** comes from each of the three groups: *Neck & shoulders*, *Back/trunk*, *Chest/arms*.
2. The remaining two are random from unused mechanics.
3. Mechanics seen in the previous session get lower weight (×0.5) so players see variety **[P]**.
4. Level B mechanics are excluded if **No-trunk mode** is on (`14` §8.8); the group rule then applies to the remaining mechanics.

**Simple problem.** The three groups have 4 + 3 + 3 mechanics. A session draws 1 from each group first (3 picks), then 2 more at random from the 7 left → 5 distinct mechanics total.

### 5.3 Hand mode `GP-HAND-01` **[S]**
`Both hands` · `Left only` · `Right only`. Disabled hands (calibration steps skipped) force one-hand mode.

### 5.4 Difficulty presets **[P]**

| Parameter | Gentle | Standard | Active |
|---|---|---|---|
| Reach factor `k` | 0.60 | 0.75 | 0.85 (max **[S]**) |
| Target radius | 0.12 m | 0.10 m | 0.08 m |
| Start tempo (rhythm mechanics) | 50 BPM | **60 BPM [S]** | 70 BPM |
| Max tempo | 70 BPM | 80 BPM | 90 BPM |
| Target lifetime `L` | 3 beats | 2 beats | 2 beats |

Mechanic-specific parameters (angles, cadence, hold times) are in each mechanic file.
`GP-DIFF-01` Difficulty is adjusted through **distance (k), size, tempo/cadence, and hold times** only.
`GP-DIFF-02` Tempo only increases when accuracy is stable (`02` §6.B).

---

## 6. The 10 mechanics (summary)

| § | Mechanic (theme) | Movement | Group | Safety level | Priority |
|---|---|---|---|---|---|
| 6.1 | Seated Boxing (Asteroid Brawler) | Light punches | Chest/arms | A | **P0** |
| 6.2 | Overhead Reach (Fruit Harvester) | Diagonal reach up | Neck & shoulders | A | P1 |
| 6.3 | Side Arm Raise (Glider Pilot) | Lateral raise, steer | Neck & shoulders | A | P1 |
| 6.4 | Trunk Twist (Turret Gunner) | Torso rotation | Back/trunk | **B** | P2 |
| 6.5 | Seated Row (Cosmic Tug-of-War) | Pull to waist | Back/trunk | A | P1 |
| 6.6 | Forward Press (Force Blast) | Press and hold | Chest/arms | A | **P0** |
| 6.7 | Arm Circles (Shield Generator Crank) | Slow circles | Neck & shoulders | A | **P0** |
| 6.8 | Neck Mobility and Far Focus (Recon Scanner) | Slow head turns | Neck & shoulders | **B** | P2 |
| 6.9 | Elbow Flexion and Wrist Pour (Potion Brewer) | Curl + wrist roll | Chest/arms | A | P1 |
| 6.10 | Overhead Reach with Side Bend (Laser Evader) | Lean sideways | Back/trunk | **B** | P2 |

Safety level **A** = arms only. Level **B** = trunk or neck movement (needs a stable-chair confirmation and its own calibration module).
**P0** = vertical slice (built first, also the Godot parity slice, see `../04-workspace-and-antigravity.md`).

---

## 11. Suggested build order (8 weeks) **[P]**

| Week | Build | Verifiable without a headset? |
|---|---|---|
| 1 | Unity setup, rig, `IPlatformServices`, EditorSim, Quest APK builds. | Build only |
| 2 | Tracking, HandTip, segment hit detection (`02` §6.C), BodyFrame. | Mostly (simulator) |
| 3 | Base calibration + save/load + obstacles; Score Attack loop skeleton (timer, draw, results). | Logic yes |
| 4 | **P0:** M01 Asteroid Brawler, M06 Force Blast, M07 Shield Crank. | Logic yes |
| 5 | **P1:** M02, M03, M05, M09. Godot parity slice starts (calibration + P0). | Logic yes |
| 6 | **P2:** M04, M08, M10 + module calibrations (twist, neck, lean) + safety levels. Godot parity continues. | Logic yes; feel no |
| 7 | UI polish, settings, results, functional + usability testing on **real Quest** (Unity and Godot builds). | **Needs headset** |
| 8 | Fixes, A/B comparison report, documentation, demo build. | **Needs headset** |

**Honest scope note:** 10 mechanics + a second engine in 8 weeks with no headset is tight. The framework (calibration, targets, hit detection, scoring) is shared, so each mechanic is small, but the P2 mechanics add calibration and safety work. If time runs short, cut Godot to the P0 slice only, not the mechanics.

---

## 12. Out of scope (do not build) **[S]**

Hand tracking (requested by 2 of the 5 visible survey rows; revisit after the core loop works) · heart-rate sensors · biomechanics analysis · cloud storage · online leaderboards · virtual instructor · clinician dashboard · **posture multipliers** (draft add-on 2, high cost) · **a reminder that works while the app is closed** (needs a phone/desktop companion; see `../research/01-survey-analysis.md`).
**Optional P2 add-on:** *Desk Mode* with passthrough (draft add-on 1), behind `IPlatformServices` (`../02-quest-config.md` spike S-4).
