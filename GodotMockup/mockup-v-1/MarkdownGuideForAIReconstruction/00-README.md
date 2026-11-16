# ZenoFit — Seated VR Fitness for Desk Workers: Spec Pack (Meta Quest)

> **Version:** 0.3 (draft) · **Date:** 2026-11-15 · **Owner:** Ryan
> This pack defines *what* we build and *how it is configured*. If code and spec disagree, fix one of them and record it in the changelog at the bottom.

**Legend used in every file**

| Tag | Meaning |
|---|---|
| **[S]** | From the source PDF or from research. |
| **[D]** | From your ZenoFit design draft. |
| **[P]** | Proposal by the spec author. A sensible default to *start* with. Tune it in testing. |
| **[V]** | Vendor/version-dependent. Verify against current Unity / Godot / Meta docs before relying on it. |
| **MUST / SHOULD / MAY** | Requirement strength. |

---

## 1. Files in this pack

| File | Read it when you need to... |
|---|---|
| `00-README.md` (this file) | Understand scope, decisions, risks, and the rules for AI assistants. |
| `01-techstack.md` | Unity build: version, packages, folder structure, conventions. |
| `02-quest-config.md` | Configure Unity for Quest 2/3/3S, build, run, and test (including **without a headset**). |
| `03-godot-build.md` | Build the **second (Godot) version** for A/B testing: concept map, setup, parity matrix, comparison plan. |
| `04-workspace-and-antigravity.md` | Folder layout, `AGENTS.md` templates, and the task list for your Antigravity agent. |
| `research/01-survey-analysis.md` | What the ZenoFit survey says (and does not say), and how it changed the design. |
| `gameplay/` | Implement the game. One file per topic (index below). |

### Gameplay files (`gameplay/`)

**Section numbers are global across the gameplay files**, so "§6.3" always means Side Arm Raise (Glider Pilot).

| File | Section(s) |
|---|---|
| `00-gameplay-overview.md` | §1 goals · §2 app flow · §5 Score Attack session, difficulty, hand mode · §6 mechanics table · §11 build order · §12 out of scope |
| `01-body-frame-and-calibration.md` | §3 BodyFrame · §4 calibration (base steps, module calibrations) |
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
| `13-scoring-and-score-attack.md` | §7 |
| `14-safety.md` | §8 |
| `15-feedback-and-ui.md` | §9 |
| `16-acceptance-tests.md` | §10 |

**Making it more specific:** each mechanic file ends with a **Tunables** table and **Open questions**. Fill in "Your value" and answer the questions; the **[P]** defaults then become decisions.

Reading order for a human: `00 → research/01 → gameplay/00 → gameplay/01 → the mechanic you are building`. For an AI assistant: section 5.

---

## 2. Product summary

**ZenoFit** is a seated VR game for **desk-working gamers and students** on **Meta Quest**. In a 3-minute **Score Attack** session (5 rounds × 30 s), the player performs simple upper-body stretches disguised as short games: punching asteroids, harvesting fruit, gliding through rings, cranking a shield, and more. Targets are placed inside the player's **own calibrated comfortable range**. **[D]**

**Ten mechanics [D]:** Seated Boxing · Overhead Reach · Side Arm Raise · Trunk Twist · Seated Row · Forward Press · Arm Circles · Neck Mobility and Far Focus · Elbow Flexion (with wrist pour) · Overhead Reach with Side Bend. (Replaces the earlier five movements of the accessibility PDF.)

**Core loop [D]:** sit down → quick seat check → 3-minute randomized Score Attack → results → repeat for a higher score.

**Constraints [D]:** VR, seated only, no extreme leg stretching, minimum 10 exercise-based mechanics, quick enough for a break.

**Principles kept from the original accessibility research [S]:** calibrated range (≤ 85 % of reach), one-hand mode, no lower-body requirement, stop at any time, no unintended locomotion, not a medical device.

---

## 3. Decision log

| ID | Decision | Status |
|---|---|---|
| D-01 | Primary engine: **Unity 6 (6000.x)**, C# | Locked |
| D-02 | XR API: **OpenXR** + XR Interaction Toolkit 3.x (Unity). No Oculus XR Plugin. | Locked **[S]** |
| D-03 | Input: **controllers only**. Hand tracking deferred (2 of 5 visible survey rows asked for it). | Locked |
| D-04 | Platform: **Meta Quest 2, 3, 3S only**. | Locked |
| D-05 | Tracking origin: **Device (seated)**; gameplay positions are relative to a calibrated BodyFrame. | Locked **[S]** |
| D-06 | Passthrough only via `IPlatformServices`, with a fallback pause scene. | Locked |
| D-07 | Local JSON persistence only. No network permission. | Locked **[S]** |
| D-08 | No headset yet: simulators + unit tests. **Real-device validation is mandatory before any demo or user test.** | Locked (until a device is available) |
| D-09 | Performance baseline: **Quest 2**. | Locked |
| D-10 | **Audience: desk-working gamers and students** (survey audience). | Locked (your decision) |
| D-11 | **Scope: the 10 draft mechanics replace the 5 PDF movements.** | Locked (your decision) |
| D-12 | **Second build in Godot** for testing, in addition to Unity (parallel, not a migration). Only the **P0 slice** is guaranteed. | Locked (your decision) |
| D-13 | Safety levels: **A** (arms only) and **B** (trunk/neck). Level B has its own calibration, limits, and a **No-trunk mode**. | Locked |
| D-14 | Reminders when the app is closed are **out of scope** (needs a phone/desktop companion). | Locked |
| D-15 | First Quest model to test on | **Open** |

---

## 4. Risks you should know about now

1. **Scope vs. time vs. hardware.** 10 mechanics + two engines in 8 weeks, with no headset, is tight. Mitigation: shared framework, **P0 → P1 → P2** order (`gameplay/00` §11), and a Godot build limited to the P0 slice if time runs short. Cut Godot before cutting mechanics (course constraint: ≥ 10).
2. **Existing Unity build vs. new spec.** ZenoFit was built before this spec. Run **Task A (audit)** in `04-workspace-and-antigravity.md` before assuming anything exists.
3. **Survey is thin.** 8 responses (5 visible), mostly peers. Use it as direction, not proof. See `research/01-survey-analysis.md`.
4. **Trunk/neck mechanics add risk.** Level B mechanics rely on proxies (controllers cannot measure torso rotation directly) and need a stable chair. Keep them P2 and behind No-trunk mode.
5. **Gaze tracking does not exist on Quest 2/3/3S** **[V]**. Recon Scanner uses head pointing.
6. **No headset = unverified feel.** Get hardware access **by the end of week 2**, or weeks 7–8 (A/B tests) will slip.
7. **Safety claims.** Reach and angle limits are sensible defaults, not clinical guidance. No health claims in the UI. **[S]**

---

## 5. Rules for AI coding assistants (read before generating code)

1. Read `00` → `research/01` → `gameplay/00` → the specific files for the task, before writing code.
2. **Do not add packages, SDKs, or plugins** that are not listed in `01-techstack.md` (Unity) or `03-godot-build.md` (Godot) without asking.
3. **Quest-specific code lives only in the platform layer** (`Scripts/Platform/Quest/` in Unity, `platform.gd` in Godot). Gameplay code calls the platform interface.
4. **No hand tracking, no cloud, no networking, no analytics.**
5. **No locomotion.** Never move, rotate, or scale the XR origin during gameplay. Never roll the world.
6. **Never place a target outside the calibrated range** (`gameplay/01` §4.3, §4.7) **or inside an obstacle exclusion zone** (§4.5).
7. **Scoring depends only on arm accuracy, rhythm, and smoothness.** Never on posture or the lower body.
8. Every number tagged **[P]** must be a tweakable field (ScriptableObject / Resource), not a magic number.
9. Pure maths in plain classes with unit tests that use the **same numbers** as `gameplay/16-acceptance-tests.md`.
10. If a requirement is ambiguous or marked **[V]**, **ask or flag it**. Do not guess silently.
11. Keep each mechanic independent: a new mechanic = one class + one config + one `gameplay/` file.
12. **No health claims** in UI text or docs ("not a medical device").
13. Godot only: convert coordinates and yaw through `core/spec_space.gd` (`03-godot-build.md` §3.1).

---

## 6. Glossary

| Term | Meaning |
|---|---|
| **OpenXR** | Open cross-vendor standard for XR devices. |
| **XRI** | Unity's XR Interaction Toolkit. |
| **Interaction profile** | OpenXR description of a controller type. Enable the profiles of your target devices or controllers won't track. |
| **Tracking origin** | Reference point for tracked positions. *Device* = headset at start (seated). *Floor* = floor height. |
| **BodyFrame** | Calibrated coordinate system: origin at the chest, +Z forward, +Y up, +X right (spec space). |
| **Score Attack** | The 3-minute session: 5 rounds × 30 s, each a different mechanic, with a combo multiplier. |
| **Safety level A / B** | A = arms only. B = trunk or neck movement (extra safety rules). |
| **No-trunk mode** | Setting that removes all Level B mechanics. |
| **P0 / P1 / P2** | Build priority. P0 = vertical slice (and the Godot parity slice). |
| **Passthrough** | Showing the real world through the headset cameras. |
| **SSQ** | Simulator Sickness Questionnaire (cybersickness measure). **[S]** |
| **Parity build** | The Godot build that must pass the same acceptance tests as Unity. |

---

## 7. Assumptions and clarifications

| # | Observation | Decision in this spec |
|---|---|---|
| A1 | Original PDF: side raise cap 60°–70° (wheelchair users). | Desk audience: presets 60° / 75° / 90° (§6.3). |
| A2 | PDF heart-rate formula is garbled (reads like `220 − age − 20`). | HR is out of scope; formula kept only as a reference (§8.7). |
| A3 | Draft: "headset gaze-tracking" for Recon Scanner. | Not on Quest 2/3/3S **[V]**. Head-pointing reticle. |
| A4 | Draft: Potion Brewer "tossing" ingredients. | Replaced by **wrist pour** (safer, measurable, covers the survey's wrist/RSI need). Toss may return as advanced mode. |
| A5 | Draft: Glider Pilot "tilting to steer". | Steering uses **arm height difference**, not body lean. World never rolls (comfort). |
| A6 | Draft: Turret Gunner needs torso rotation. | Controllers cannot measure the torso; proxy = hands near chest + hand-midpoint yaw. Limitation documented **[V]**. |
| A7 | Draft: Recon Scanner "far focus" for eye strain. | VR has a fixed focal distance **[V]**, so no eye-relief claim; far-look break uses passthrough + the real room. |
| A8 | Draft add-on 1: Passthrough Desk Mode. | Optional P2, behind the platform interface. |
| A9 | Draft add-on 2: posture-based multipliers. | **Deferred** (high cost, risk of frustration). |
| A10 | Survey: reminder timer is a top feature. | A headset app cannot remind a non-wearing user. Out of scope; companion needed (D-14). |
| A11 | Survey: hand tracking requested. | Deferred; controllers first (D-03). |
| A12 | Wheelchair-specific content in the PDF. | Principles kept (calibrated range, one-hand mode, stop anytime); wheelchair-specific guidance is no longer the primary audience (D-10). |

---

## 8. Open questions

1. Which Quest model will you get hands on first, and when? (D-15)
2. Does the course require **all 10 mechanics implemented** by the deadline, or 10 *designed*? (This decides whether P2 can slip.)
3. What is the concept text shown to survey respondents? (Needed to interpret the interest ratings.)
4. Who can review safety defaults (a physiotherapist or similar) before user tests?
5. Do you need a Meta Store release, or is sideloading enough for the demo?

---

## 9. Changelog

| Date | Change |
|---|---|
| 2026-11-11 | v0.1 initial draft (Quest + PICO, single gameplay file). |
| 2026-11-12 | v0.2: Meta Quest only; gameplay split into files with Tunables + Open questions. |
| 2026-11-15 | v0.3: desk-gamer audience; the 10 mechanics replace the 5 (one file each); Score Attack loop; safety levels A/B; survey analysis added; Godot parallel build and Antigravity workspace guide added. |
