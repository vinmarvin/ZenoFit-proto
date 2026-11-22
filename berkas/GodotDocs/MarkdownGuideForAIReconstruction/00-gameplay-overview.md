# Gameplay Overview (v0.4 — Zen Dojo Arcade)

> Part of the **ZenoFit AI Reconstruction Spec Pack (Godot 4.7)**. **Section numbers are global across all gameplay files**, so §6.3 always refers to `M03` (*Crane Wings / Side Arm Raise*).
> Legend: **[S]** source/research · **[D]** locked team decision · **[P]** tunable default · **[V]** verify on hardware.

---

## 1. Experience goals

| # | Goal | Source |
|---|---|---|
| G1 | The user is **100% seated, upper-body only**. No standing, squatting, or leg movement. | [D] [S] |
| G2 | Every target stays inside the user's **calibrated comfortable range** (`k <= 0.85`) and outside desk obstacles. | [S] |
| G3 | Gameplay feels like a **snappy Zen Dojo Arcade Score Attack**, never a forced workout; scoring rewards real physical upper-body motion (**zero raycast / zero stationary-hand exploits**). | [D] |
| G4 | **Zero unintended locomotion.** Fixed seated camera; Zen Dojo tatami & shoji provide a calm static visual reference frame. | [S] [D] |
| G5 | Supports **Hybrid OpenXR Hand Tracking (primary) + Handheld Controller (fallback)**, one-hand or two-hand mode, and pause/stop at any time. | [D] [S] |
| G6 | Mobile VR performance **72–90 FPS** on **PICO 4 Ultra** and **Meta Quest 2 / 3 / 3S**. | [D] |
| G7 | Default **Quick Trial fits a 3-minute work break** (`5 rounds × 30 s`), with optional `6 min` / `10 min` Extended sessions. | [D] |
| G8 | Returning user time-to-first-target is short (**<= 10 s Quick Seat Check**, <= 30 s total). | [D] [P] |

---

## 2. App flow (v0.4 Player Flow State Machine)

```text
Boot -> HandPresenceCheck -> [FirstLaunchSafetyNotice] -> MainMenu (Play | Settings | Credits | Quit)
                                                              ▲
      ┌───────────────────────────────────────────────────────┘
      │  (Play)
      ▼
[Guided Calibration (first run, ~35s) OR Quick Seat Check (returning, <=10s)]
      │
      ▼
RoutinePicker (Full Upper-Body Reset | Arms & Shoulders | Back & Posture) + Duration (3m | 6m | 10m)
      │
      ▼
[Optional WarmUp (15–20 s, skippable — Xu et al. 2020 Guideline #1)]
      │
      ▼
SessionStart ─► ┌──► RoundIntro (4 s, Zeno demo) ─► RoundPlay (30 s, NO raycast) ─► RoundOutro (2 s) ──┐
                └── (5 rounds = 3m; 10/15 rounds = 6m/10m with MidSession Zen Breather Passthrough) ◄──┘
      │
      ▼
Results (Total Score, Max Streak, Accuracy %, Dojo Mastery Rank, Personal Best, Body Areas Covered)
      │
      └──► Play Again / Routine Picker / Main Menu

Any Round state ◄─► Paused (Lap Rest 2s + Passthrough, Lean Warning, Rest Reminder, Recenter, Stable Chair, Manual)
```

| State | Entry & Behaviour | Exit |
|---|---|---|
| **Boot** | Init OpenXR (`Local`), load `calibration_profile.json`, `sessions.json`, `settings.json`, spawn Zen Dojo & ZenoBot. | Ready → `HandPresenceCheck` / `MainMenu`. |
| **HandPresenceCheck** | If Hand Tracking active and hands not visible, Zeno raises palms (*"Raise both hands so I can see you!"*). Skipped if controllers are active. | Hands/controllers tracked → Notice (if first launch) or `MainMenu`. |
| **MainMenu** | 4 primary buttons: **`Play`**, **`Settings`**, **`Credits`**, **`Quit`** (`get_tree().quit()` after confirm). Also offers *Practice Mode* drawer. | `Play` → Calibration / Quick Seat Check. |
| **Calibration** | First run: Seat Anchor → Reach L/R (skip = One-Hand) → Lap Point → Desk Obstacles (optional) → **Chair Type Check** (Stable vs. Swivel = auto No-Trunk). Returning: **Quick Seat Check (`<= 10 s`)**. | Confirmed → save JSON → `RoutinePicker`. |
| **RoutinePicker** | Select Routine (`Full Upper-Body Reset`, `Arms & Shoulders`, `Back & Posture`) + Duration (`3 min` default, `6 min`, `10 min`). Non-medical copy (NO *"Sores"*, NO leg/foot icons). | `Start` → Optional `WarmUp` → `SessionStart`. |
| **WarmUp** *(optional)* | 15–20 s skippable gentle reach & wrist circle warm-up to reduce seated early misses (Xu et al., 2020). | Done / Skip → `SessionStart`. |
| **SessionStart** | Draws balanced round lineup for chosen Routine, honoring `No-Trunk Mode` and non-consecutive `Level B`. | → `RoundIntro` (index 0). |
| **RoundIntro** | `4.0 s`: shows Zen Dojo mechanic title, one-line cue, Safety Level B note if applicable, and Zeno procedural demo. | Timer → `RoundPlay`. |
| **RoundPlay** | `30.0 s` active arcade round. **NO raycast.** Combo carries across rounds. | Timer → `RoundOutro`. |
| **RoundOutro** | `2.0 s` round score summary; on Extended `6/10 min` sessions triggers a `20–30 s` **Zen Breather (Passthrough ON)** between 5-round stages. | Next round or `Results`. |
| **Results** | Shows Total Score, Accuracy %, Hits/Misses, Max Streak, **Dojo Mastery Rank (`C / B / A / S / Zen Master`)**, **New Personal Best badge**, and Body Areas Covered. | *Play Again* / *Change Routine* / *Main Menu*. |
| **Paused** | Instant freeze (within 1 frame); Resume runs a `3.0 s` countdown (`GP-FLOW-02`). | *Resume* / *Recalibrate* / *Stop → Results* / *Main Menu*. |

---

## 5. Arcade Score Attack, 3 Routines, Difficulty, & Hand Mode

### 5.1 Session Structure & Durations **[D][P]**

| Option | Structure | Notes |
|---|---|---|
| **Quick Trial (`3 min`, default)** | 5 rounds × `(4 s intro + 30 s play + 2 s outro)` = `180 s` | Fits a short desk break; optimal for neck comfort. |
| **Extended (`6 min`)** | 2 stages × 5 rounds + 1 `20 s` *Zen Breather* (Passthrough) | For users wanting a longer session. |
| **Extended (`10 min`)** | 3 stages × 5 rounds + 2 `30 s` *Zen Breathers* (Passthrough) | Mandatory mid-session breaks prevent neck/sopite fatigue (Xu et al. 2020). |
| **Practice Mode** | Pick any 1 mechanic (`M01`–`M10`), 30 s rounds, no combo reset. | Ideal for learning form or testing a single mechanic. |

### 5.2 Routine Draw Rules (`GP-SESS-01` & `GP-ROUTINE-01`) **[D]**

1. **Routine 1 — `FULL_UPPER_BODY` (*Full Upper-Body Reset*):**
   - Draws **5 distinct mechanics** from all 10 (`M01`–`M10`), guaranteeing at least 1 from each body group (*Neck & Shoulders*, *Back/Trunk*, *Chest & Arms*), `×0.5` weight on mechanics from the previous session, and **never two `Level B` rounds consecutively**.
2. **Routine 2 — `ARMS_AND_SHOULDERS` (*Arms & Shoulders*):**
   - Draws **5 distinct mechanics** from the **6 `Level A` arm/shoulder pool**: `M01, M02, M03, M06, M07, M09` (`100% Level A` — safe on any swivel/rolling chair).
3. **Routine 3 — `BACK_AND_POSTURE` (*Back & Posture*):**
   - Draws **5 distinct mechanics** prioritizing the back/neck pool: `M05` (`Lvl A`), `M04` (`Lvl B`), `M08` (`Lvl B`), `M10` (`Lvl B`), plus **1 posture-opening shoulder mechanic** (`M02` or `M07`, `Lvl A`) interleaved so **`Level B` rounds are never consecutive** (e.g., `B - A - B - A - B` or `A - B - A - B - A`).
   - If **`No-Trunk Mode`** is ON (swivel chair), excludes `M04, M08, M10` and fills the 5 rounds with `M05` + posture/arm `Level A` mechanics (`M02, M03, M07, M06`).

### 5.3 Hand Mode `GP-HAND-01` **[S]**
`Both hands` · `Left only` · `Right only`. Skipping a hand during calibration disables it and forces one-hand mode. All 10 mechanics (especially `M03`, `M05`, `M07`, `M09`) MUST gracefully support one-hand mode.

### 5.4 Difficulty Presets **[P]**

| Parameter | Gentle | Standard | Active |
|---|---|---|---|
| Reach factor `k` | 0.60 | 0.75 | 0.85 (hard max **[S]**) |
| Target radius | 0.12 m | 0.10 m | 0.08 m |
| Start tempo (rhythm mechanics) | 50 BPM | **60 BPM [S]** | 70 BPM |
| Max tempo | 70 BPM | 80 BPM | 90 BPM |
| Target lifetime `L` | 3 beats | 2 beats | 2 beats |

---

## 6. The 10 Zen Dojo Arcade Mechanics (Week 14 Locked Scope)

*(Rename enum IDs, class names, folders `godot/mechanics/m01_makiwara_strikes` .. `m10_bamboo_sway`, UI titles, hints, and props strictly to the Zen Dojo names below—do not leave old names.)*

| § | ID | Zen Dojo Title | Real Movement | Group | Safety | Scoring Rule | Key v0.4 Code Fix Needed |
|---|---|---|---|---|---|---|---|
| 6.1 | `M01` | **Makiwara Strikes** | Light forward punches | Chest/arms | A | Speed + Timeliness | Require forward velocity `v_z >= 0.25 m/s` & guard return (`z <= 0.25 m`) to block stationary-hand cheat. |
| 6.2 | `M02` | **Sakura Catch** | Diagonal reach up | Neck & shoulders | A | Timeliness + Golden | Add subtle arm-lower reset or alternating X/Y spread so holding hands static above head cannot auto-farm. |
| 6.3 | `M03` | **Crane Wings** | Lateral raise (*scapular plane*) | Neck & shoulders | A | Accuracy + Wing Hold | **Fix partial:** validate span `>= 0.70 * calibrated_span` & abduction `θ ± 15°` before awarding `+10 pts/s`; support one-hand mode. |
| 6.4 | `M04` | **Bokken Guard** | Seated torso rotation | Back/trunk | **B** | **Precision only** | Tighten chest distance `0.45 -> 0.35 m` + add head-hand yaw cross-check (`|ψ_head - ψ_hands| <= 20°`). |
| 6.5 | `M05` | **Temple Bell Pull** | Two-hand seated row | Back/trunk | A | Full-stroke completion | **Fix partial:** track BOTH hands in `BOTH_HANDS` mode (fix `pick_hand_for_spawn(0)` bug), check grasp/grip, add `2.0 s` stroke timeout. |
| 6.6 | `M06` | **Ki Palm Push** | Forward press + 2 s hold | Chest/arms | A | Charge + Sync bonus | Add mandatory retract hysteresis (`z <= z_plane - 0.10 m`) after cooldown before next charge starts. |
| 6.7 | `M07` | **Zen Water Wheel** | Slow chest arm circles | Neck & shoulders | A | Smooth cadence band | **Fix partial:** evaluate BOTH hands (not right-only) and replace `absf(d_angle)` with **signed angle** matching `CW/CCW`. |
| 6.8 | `M08` | **Zen Horizon Watch** | Slow neck yaw scan | Neck & shoulders | **B** | **Smoothness only** | **Fix partial:** add pitch check (`±20°`) and optional `20 s` Passthrough Far-Look Break cue. |
| 6.9 | `M09` | **Tea Ceremony Pour** | Biceps curl + wrist pour | Chest/arms | A | Curl + Over-cup pour | **Fix partial:** validate hand is above cauldron/cup (`|x_hand - x_cup| <= 0.14 m`) during `wrist_roll >= 60°`; alternate hands in `BOTH_HANDS`. |
| 6.10 | `M10` | **Bamboo Sway** | Overhead rail + side bend | Back/trunk | **B** | **Precision + Safe Lean** | **Fix partial:** validate hands are holding overhead bo-staff (`y_hand >= y_rail - 0.15 m`); pause wall if released. |

---

## 11. Two-Week Sprint Plan to Week 14 User Evaluation **[D]**

| Sprint Slice | Owner | Deliverables |
|---|---|---|
| **Slice 1 (Days 1–4)** | Architect | Implement anti-cheat fixes for `M01, M03, M04, M05, M06, M07, M08, M09, M10` + add `AT-29`–`AT-34` headless tests (all passing). |
| **Slice 2 (Days 4–7)** | Architect + PM/UI | Implement `RoutinePicker` (3 Routines + `3/6/10 min`), `MainMenu` (`Play/Settings/Credits/Quit`), Optional `WarmUp`, **Dojo Mastery Rank + Personal Best** (`AT-35`), and **Hybrid OpenXR Hand Tracking** (`XRHandTracker` + controller fallback). |
| **Slice 3 (Days 7–10)** | PM/UI + UX Research | Integrate **Zen Dojo Environment** (`<= 120k tris`), optimized **Zeno (`19.9k tris`)**, Dojo SFX audio (with combo pitch escalation) & lightweight hit particles; verify **72–90 FPS** on PICO 4 Ultra & Meta Quest 3. |
| **Slice 4 (Days 11–14)** | Whole Team | Playtest bug-bash, build final APKs for PICO 4 Ultra & Meta Quest 3, run Week 14 user evaluation (task completion, IMI, MSAQ/SSQ vs. seated YouTube video baseline). |

---

## 12. Out of Scope (Do Not Build Before Week 14) **[D]**

- Extra new mechanics (`M11 Dojo Gate Opener`, `M12 Rei Breath`, `M13 Ink Spiral`) — *Post-Week 14 stretch only*.
- Belt progression system (`White → Black Belt`) — *dropped; use Dojo Mastery Rank + Personal Best only*.
- Off-headset break reminder companion app (phone/desktop).
- Heart-rate sensors, eye tracking, foot/lower-body tracking, cloud storage, online leaderboards, clinician dashboards.
