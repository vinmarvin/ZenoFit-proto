# Accessible Seated VR Fitness App — Spec Pack (Meta Quest)

> **Version:** 0.2 (draft) · **Date:** 2026-11-12 · **Owner:** Ryan
> This pack defines *what* we build and *how it is configured*. If code and spec disagree, fix one of them and record it in the changelog at the bottom.

**Legend used in every file**

| Tag | Meaning |
|---|---|
| **[S]** | Comes directly from the source PDF (user research / technical requirements). |
| **[P]** | Proposal by the spec author. A sensible default to *start* with. Tune it in usability testing. |
| **[V]** | Vendor-dependent. Verify against the current Unity / Meta documentation before relying on it. |
| **MUST / SHOULD / MAY** | Requirement strength (MUST = needed for the 8-week prototype). |

---

## 1. Files in this pack

| File | Read it when you need to... |
|---|---|
| `00-README.md` (this file) | Understand scope, decisions, risks, and the rules for AI assistants. |
| `01-techstack.md` | Know the Unity version, packages, folder structure, and conventions. |
| `02-quest-config.md` | Configure Unity for Quest 2/3/3S, build, run, and test (including **without a headset**). |
| `gameplay/` | Implement the game. One focused file per topic (index below). |

### Gameplay files (`gameplay/`)

**Section numbers are global across the gameplay files**, so "§6.3" always means Side Arm Raise, no matter which file you are in.

| File | Section(s) |
|---|---|
| `00-gameplay-overview.md` | §1 goals · §2 app flow · §5 session, difficulty, hand mode · §11 build order · §12 out of scope |
| `01-body-frame-and-calibration.md` | §3 BodyFrame · §4 calibration |
| `02-targets-and-hit-detection.md` | §6.0 shared rules · §6.4 adaptive tempo · §6.7 hit detection |
| `03-ex-forward-arm-reach.md` | §6.1 |
| `04-ex-alternating-arm-reach.md` | §6.2 |
| `05-ex-side-arm-raise.md` | §6.3 |
| `06-ex-forward-press.md` | §6.5 |
| `07-ex-seated-boxing.md` | §6.6 |
| `08-scoring-and-results.md` | §7 |
| `09-safety.md` | §8 |
| `10-feedback-and-ui.md` | §9 |
| `11-acceptance-tests.md` | §10 |

**Making it more specific:** each exercise file (and several others) ends with a **Tunables** table and an **Open questions** list. Fill in the "Your value" column and answer the questions; the **[P]** defaults then become decisions. When one topic grows large, split it into its own file and keep the global section numbers.

Recommended reading order for a human: `00 → gameplay/00 → gameplay/01 → 01 → 02`. For an AI assistant: see section 5.

---

## 2. Product summary

An **accessible, seated, upper-body VR fitness prototype** for people with lower-body mobility limits (primarily wheelchair users), running on **Meta Quest**. The user performs five seated arm exercises as short VR minigames. Targets are placed inside the user's *own calibrated comfortable reach*, scoring never penalises lower-body movement, and safety features (pause, rest reminders, reach limits) are built in. **[S]**

**Prototype exercises [S]:** Forward Arm Reach · Alternating Arm Reach · Side Arm Raise · Forward Press · Seated Boxing.

**Non-goals for the prototype [S]:** hand tracking, heart-rate sensor integration, biomechanics analysis, cloud storage, medical/rehabilitation claims.

**Not a medical device [S].** Movement protocols must be reviewed by a physiotherapist before testing with at-risk users.

---

## 3. Decision log

| ID | Decision | Status |
|---|---|---|
| D-01 | Engine: **Unity 6 (6000.x)**, C# | Locked |
| D-02 | XR API: **OpenXR** via the Unity OpenXR Plugin + **XR Interaction Toolkit (XRI) 3.x**. We do **not** use the Oculus XR Plugin. | Locked **[S]** |
| D-03 | Input: **controllers only**. No hand tracking in the prototype. | Locked **[S]** |
| D-04 | **Target platform: Meta Quest 2, 3, and 3S only.** PICO 4 Ultra is out of scope. | Locked |
| D-05 | Tracking origin: **Device (eye-level / seated)**, *not* Floor. All gameplay positions are relative to a calibrated body frame. This removes the floor "Y-offset" problem reported by seated users. **[S]** | Locked |
| D-06 | Passthrough (needed for "hands in lap → auto-pause" **[S]**) is accessed **only** through `IPlatformServices`, with a fallback pause scene if it is unavailable. | Locked |
| D-07 | Persistence: **local JSON only** (calibration + session history). No network permission. | Locked **[S]** |
| D-08 | Development without a headset: XRI Interaction Simulator + Meta XR Simulator + unit tests. **Real-device validation is mandatory before any demo or user test.** | Locked (until a device is available) |
| D-09 | Performance baseline: **Quest 2** (weakest). | Locked |
| D-10 | **First Quest model to test on: TBD** (whichever you can physically access first). | **Open** |

---

## 4. Risks you should know about now

1. **No headset = unverified core assumptions.** The PDF plan has "Meta Quest running" at week 1. Without hardware you can only verify that the project *builds* and works in a simulator. Tracking feel, haptics, comfort, and performance cannot be validated in a simulator. Get hardware access (campus lab, a peer, a borrowed device) **by the end of week 2**, or accept that weeks 7–8 (usability testing) will slip.
2. **Passthrough is the most Quest-specific feature in the plan** (and Quest 2 passthrough is black-and-white **[V]**). That is why it is hidden behind an interface with a fallback.
3. **Safety claims.** Reach limits (≤ 85 % of max reach) and angle limits are sensible defaults, not clinical guidance. Keep the "not a medical device" wording in the app and docs. **[S]**

---

## 5. Rules for AI coding assistants (read before generating code)

1. Read `00` → `01` → `02` → `gameplay/00` and then the specific gameplay file for the task, before writing code.
2. **Do not add packages, SDKs, or plugins** that are not listed in `01-techstack.md` without asking.
3. **Quest-specific code (Meta APIs) lives only in `Assets/_Project/Scripts/Platform/Quest/`.** Gameplay, UI, calibration, and safety code must call `IPlatformServices`, never a Meta API directly.
4. **No hand tracking, no XR Hands, no cloud, no networking, no analytics.**
5. **No locomotion.** The camera moves only with the user's real head movement. Never move, rotate, or scale the XR Origin during gameplay.
6. **Never position a target outside the user's calibrated comfort envelope** (`gameplay/01-body-frame-and-calibration.md` §4.3), and never inside an obstacle exclusion zone (§4.5).
7. **Scoring never penalises lower-body movement or body posture.** Score depends only on arm accuracy and rhythm.
8. Every number tagged **[P]** must be a serialized, tweakable field (ScriptableObject), not a magic number in code.
9. Put pure maths (reach, angles, BPM, scoring) in plain C# classes with **EditMode unit tests**; keep `MonoBehaviour`s thin.
10. If a requirement is ambiguous or marked **[V]**, **ask or flag it**. Do not guess silently.
11. Keep each exercise independent: a new exercise = one new class + one new ScriptableObject config + one new `gameplay/` file. No edits to other exercises.

---

## 6. Glossary

| Term | Meaning |
|---|---|
| **OpenXR** | Open, cross-vendor standard for XR devices. Unity talks to the headset through it. |
| **XRI** | XR Interaction Toolkit: Unity's package for XR rigs, controllers, and interactions. |
| **Interaction profile** | OpenXR's description of a controller type (button/pose/haptic layout). You must enable the profiles of the devices you target, or the controllers won't track. |
| **Tracking origin** | The reference point for tracked positions. *Device* = origin at the headset at start (good for seated). *Floor* = origin on the floor (needs correct floor height). |
| **Reach envelope** | The 3D region the user can comfortably reach. Targets are placed inside it. |
| **Passthrough** | Showing the real world through the headset cameras. |
| **Haptics** | Controller vibration feedback. In Unity you control amplitude and duration (not true frequency). |
| **SSQ** | Simulator Sickness Questionnaire: standard measure of cybersickness. **[S]** |
| **BodyFrame** | Our calibrated coordinate system: origin at the user's chest, +Z forward, +Y up, +X right (`gameplay/01-…` §3). |

---

## 7. Assumptions and clarifications on the source PDF

| # | Observation in PDF | Decision in this spec |
|---|---|---|
| A1 | Side Arm Raise limit is written "60°–70°". | Default max **60°**, hard cap **70°**, configurable. |
| A2 | Heart-rate formula text is garbled; it reads like `HRpeak = 220 − age − 20`. | Not used in the prototype (HR sensors are out of scope **[S]**). Verify against the source paper before using it later. |
| A3 | UX section proposes an HR safety cut-off (> 86 % HRpeak), but the technical section excludes HR sensors. | **Deferred.** Safety relies on pause, rest reminders, and reach limits. |
| A4 | Seated Boxing must avoid "sudden jerky movements" yet is also a punch. | Hits are valid on contact; speed only changes feedback strength. No penalty for slow movement and no maximum speed (§6.6). |
| A5 | "Hands in lap for 2 s → auto-pause + passthrough". | Lap position is **calibrated**, not guessed (§4.2 step 6, §8.1). |
| A6 | Passthrough is required for auto-pause but is device-specific. | Hidden behind `IPlatformServices` + fallback scene (D-06). |
| A7 | Haptics: "low-frequency vibration for a good punch, soft for light touch". | Unity exposes amplitude + duration only; frequency is approximated by longer/stronger vs shorter/weaker pulses. |
| A8 | Source plan names Quest 2/3 only. | Spec covers Quest 2, 3, and 3S. PICO 4 Ultra was considered and dropped. |
| A9 | Shoulder Rolls, Elbow Flexion, Seated Swimming, Biceps Curl, Seated Row, virtual instructor. | **Deferred.** Not in the 5 prototype exercises. |

---

## 8. Open questions

1. Which Quest model will you get hands on first, and when? (D-10)
2. Is there a physiotherapist/clinician contact for reviewing movements before user tests?
3. Will usability testing include real wheelchair users, or healthy participants seated in a chair first? (Recommended: seated healthy participants first.)
4. Do you need a Meta Store release, or is sideloading enough for the demo? (Affects target API level and manifest requirements.)

---

## 9. Changelog

| Date | Change |
|---|---|
| 2026-11-11 | v0.1 initial draft (Quest + PICO, single gameplay file). |
| 2026-11-12 | v0.2: Meta Quest only (PICO removed); gameplay spec split into `gameplay/` files with Tunables + Open questions. |
