# 04 — Workspace and Antigravity Workflow

> Legend: **[P]** proposal · **[V]** verify. Folder names are **placeholders**: adapt them to what already exists in your XR project root.
> Goal: let Antigravity (your AI agent, running at the XR project root) work on **both** the Unity and the Godot build from one source of truth: the spec pack.

## 1. How Antigravity reads rules (verified from its docs) **[V]**

- It loads rule files from your workspace folder **and from every parent folder up to the repository root**: `AGENTS.md`, `GEMINI.md`, or `.agents/rules/*.md` (legacy `.agent/rules/`).
- **Directory-scoped rules:** when the agent reads or edits a file, it walks up the directory tree from that file and loads rules at each level. So a `unity/AGENTS.md` and a `godot/AGENTS.md` apply only when the agent works inside those folders.
- `GEMINI.md` is Antigravity-only and takes precedence over `AGENTS.md`. `AGENTS.md` is also read by Claude Code, Cursor, and Codex, so it is the better default for shared rules.
- Rule files can reference other files with `@` syntax, so a short rule file can point to the spec instead of copying it.
- A third-party summary mentions a **12,000-character limit per rule file** **[V]**. Keep rule files short and point to the spec.
- Versions differ (CLI vs app vs IDE). If a rule seems ignored, test with a harmless marker line ("when asked for the repo codename, answer ORBIT-CHECK") in a **new** conversation.

## 2. Recommended folder layout **[P]**

```
xr-project/                      ← Antigravity workspace root (repository root)
├─ AGENTS.md                     shared rules (short; points to spec/)
├─ spec/                         THIS pack (source of truth). Contents of spec-pack/
│   ├─ 00-README.md … 04-…
│   ├─ gameplay/
│   └─ research/                 anonymized analysis only (no raw CSV with names/IDs)
├─ unity/ZenoFit/                existing Unity project
│   └─ AGENTS.md                 Unity-only rules
├─ godot/ZenoFit/                new Godot project
│   └─ AGENTS.md                 Godot-only rules
└─ docs/
    ├─ unity-audit.md            output of the audit task (§4, task A)
    └─ parity-matrix.md          copy of the table in 03-godot-build.md §7
```

- Use **one Git repository** for all of it, so the agent can see the spec, the Unity code, and the Godot code together.
- `.gitignore`: Unity (`Library/`, `Temp/`, `Logs/`, `obj/`, `Builds/`, `UserSettings/`) and Godot (`.godot/`, `android/build/`, `*.apk`, `*.aab`). Keystores and signing passwords stay **outside** the repo.
- Keep your raw survey CSV **outside** the repo (it contains names and student IDs).

## 3. Rule file templates

### 3.1 Root `AGENTS.md` (shared)

```markdown
# ZenoFit XR project: shared rules

## What this is
Seated VR fitness game for Meta Quest 2/3/3S. Two builds: Unity (primary) and Godot (parity test build).
The single source of truth for behavior is `spec/`. Read `spec/00-README.md` first, then the gameplay
file for the task (e.g. `spec/gameplay/08-m06-force-blast.md`).

## Hard rules
1. Do not change behavior, numbers, or formulas unless the spec says so. If the spec is wrong or unclear,
   STOP and ask; propose a spec edit first.
2. Numbers tagged [P] in the spec must be configurable (ScriptableObject in Unity, Resource in Godot).
3. Controllers only. No hand tracking, no networking, no cloud, no analytics.
4. No locomotion: never move, rotate, or scale the XR origin during gameplay.
5. Never place a target outside the calibrated comfort range or inside an obstacle exclusion zone.
6. Score depends only on arm accuracy and rhythm. Never on posture or the lower body.
7. Do not edit anything under `spec/` unless explicitly asked.
8. Do not add dependencies/packages/plugins without asking.
9. Work in small slices. Plan first, then implement, then list what you changed and which acceptance
   tests (`spec/gameplay/16-acceptance-tests.md`) you ran.

## Safety wording
The app is not a medical device. Never add health or treatment claims to UI text or docs.

## Privacy
Never read, copy, or commit raw survey files that contain names or student IDs.
```

### 3.2 `unity/AGENTS.md`

```markdown
# Unity build rules
- Unity 6 (6000.x), C#, OpenXR + XR Interaction Toolkit 3.x, Input System, URP. Tracking origin = Device.
- Meta/Quest-specific code only in `Assets/_Project/Scripts/Platform/Quest/`. Gameplay calls `IPlatformServices`.
- Pure maths in plain C# classes with EditMode tests. MonoBehaviours stay thin.
- Do not edit `Library/`, `Temp/`, `.meta` files by hand, or Packages/manifest.json without asking.
- See `spec/01-techstack.md` and `spec/02-quest-config.md`.
```

### 3.3 `godot/AGENTS.md`

```markdown
# Godot build rules
- Godot 4.6+ (check current stable), GDScript only, Compatibility renderer, OpenXR + OpenXR Vendors plugin.
- Spec space is x right, y up, z FORWARD. Godot is z BACK. Convert ONLY via `core/spec_space.gd`.
  Yaw: spec positive = turn right; Godot positive = turn left. See `spec/03-godot-build.md` §3.1.
- Pure maths in `core/` with GUT tests that use the SAME numbers as `spec/gameplay/16-acceptance-tests.md`.
- Platform-specific calls (haptics, passthrough) only through the `platform.gd` autoload.
- Use a different Android package name from the Unity build. See `spec/03-godot-build.md`.
- Port by spec, not by translating Unity files line by line. The Unity code is a reference for logic only.
```

## 4. Tasks to give Antigravity (copy-paste), in this order

Run each task in a **new conversation**, review the plan before approving, and commit after each one.

### Task A — Audit the existing Unity build (no code changes)

```text
Read spec/00-README.md and spec/gameplay/00-gameplay-overview.md.
Then inspect unity/ZenoFit (read-only). Do NOT modify any file.
Write docs/unity-audit.md with a table: spec item (section number) | exists / partial / missing |
file(s) where it is implemented | differences from the spec (numbers, formulas, behavior).
Cover: calibration, hit detection, Score Attack loop, each of the 10 mechanics, safety, haptics,
persistence, platform abstraction. End with the 10 most important gaps ordered by impact.
```
*Why first:* you built ZenoFit before the 10-mechanic spec. This task tells you what is real before anything gets ported. It also builds your own understanding of the codebase.

### Task B — Fix the P0 gaps in Unity

```text
Using docs/unity-audit.md and the spec, implement only the P0 items: calibration base steps,
segment hit detection, Score Attack loop skeleton, M01, M06, M07. Show a plan first.
Add EditMode tests for every formula in spec/gameplay/16-acceptance-tests.md that applies (AT-01, 05, 06, 07,
08, 12, 13, 21, 22, 27). Do not touch P1/P2 mechanics.
```

### Task C — Create the Godot skeleton

```text
Create godot/ZenoFit following spec/03-godot-build.md sections 4 and 5. Include: project settings for OpenXR,
the XR rig scene, platform.gd with a desktop simulator fallback, core/spec_space.gd with GUT tests for the
z-flip and yaw-sign conversion. Do not implement mechanics yet. List every manual editor step I must do myself
(export preset, Android build template, vendors plugin).
```

### Task D — Port one slice at a time

```text
Port ONLY: <slice name, e.g. "segment hit detection + AT-13">.
Use the spec and the Unity code as reference. Write the GUT tests first, with the same numbers as the
acceptance tests. Then implement. Report which tests pass. Update docs/parity-matrix.md.
```
Slice order: `core` maths → BodyFrame + calibration → Score Attack loop → M01 → M06 → M07.

## 5. Working rules for you (not the agent)

1. **Spec first:** if you change a behavior, change the spec file first, then ask the agent to follow.
2. **One slice = one commit.** If a task touches more than ~10 files, split it.
3. **Read what it wrote.** You are learning Unity and XR; skipping the review loses that benefit. Ask the agent to explain any formula it implements in your own spec's words.
4. **Do not let both engines drift:** after any numeric change, re-run the tests in both projects.
5. **Keep your attention narrow:** P0 slice first, both engines. Only then P1, then P2.

## 6. Quick checklist before the first agent session

- [ ] `spec-pack/` copied into `xr-project/spec/`.
- [ ] Root `AGENTS.md`, `unity/AGENTS.md`, `godot/AGENTS.md` created (templates above).
- [ ] Raw survey CSV removed from the repo (or ignored).
- [ ] `.gitignore` updated for Unity and Godot.
- [ ] Marker test done: new conversation, ask the agent to name the project's hard rules.
