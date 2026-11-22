# 04 — Workspace Layout & AI Agent Revision Workflow (v0.4 — Godot 4.7 Only)

> **Updated:** 2026-11-22 (Post-reorganization into 3 main folders: `berkas/`, `godot/`, `asset/`).
> **Goal:** Give AI coding assistants clear, slice-by-slice prompts to upgrade `godot/` for the **Week 14 User Evaluation** in 2 weeks without breaking existing acceptance tests.

---

## 1. Current Repository Structure

```text
XR-FP/
├─ README.md                                  # Project map, Demo link, & GA3 Provenance Row
├─ .gitignore                                 # Godot 4.x & Android build artifacts
├─ berkas/
│  ├─ BerkasFP/                               # Course submission copies (Proposal Contract, GA3)
│  ├─ Ideation/                               # Zenofit Analysis.md, Jaras Pengguna.csv (anonymized), Xu et al. (2020)
│  ├─ Exercise Analysis/                      # Reference PDFs + Godot forensic audit & architecture map
│  └─ GodotDocs/                              # THIS spec pack + AGENTS.md + Developer guides
├─ godot/                                     # Active Godot 4.7 OpenXR prototype (code & in-engine assets ONLY)
└─ asset/                                     # Raw source 3D assets (Floating Mascots.glb, Zeno.obj)
```

---

## 2. Ordered AI Revision Tasks (Copy-Paste Prompts for Week 14 Sprint)

Execute **one slice per session**, verify `godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd` passes (`0 failed`), then commit.

### Slice 1 — Fix Partial Mechanics & Anti-Cheat (`AT-29`–`AT-34`)
```text
Read berkas/GodotDocs/AGENTS.md, berkas/GodotDocs/MarkdownGuideForAIReconstruction/02-targets-and-hit-detection.md,
and 03-m01 through 12-m10 plus 16-acceptance-tests.md.
Update godot/core/mechanics_math.gd and godot/mechanics/m01..m10 to:
1. Enforce GP-ANTI-CHEAT-01 (no stationary-hand farming in M01, span+abduction check & one-hand fallback in M03,
   0.35 m chest distance + head-hand yaw cross-check in M04, bilateral stroke + 2.0 s timeout in M05,
   retract hysteresis in M06, bilateral signed-angle circles in M07, pitch check in M08,
   over-cup horizontal check & alternating hands in M09, overhead rail hold check in M10).
2. Rename all 10 mechanic enum IDs, class names, folders (`godot/mechanics/m01_makiwara_strikes` .. `m10_bamboo_sway`), UI titles, and `status_hint` strings strictly to the v0.4 Zen Dojo Arcade names (remove all old names).
3. Keep AT-01..AT-28 passing AND add automated tests AT-29..AT-34 in godot/tests/test_acceptance_suite.gd.
Run the headless acceptance test suite and report results.
```

### Slice 2 — Player Flow, 3 Routines, Main Menu (`Play/Settings/Credits/Quit`), & Rank/Personal Best (`AT-35`)
```text
Read berkas/GodotDocs/MarkdownGuideForAIReconstruction/00-gameplay-overview.md,
13-scoring-and-score-attack.md, and 15-feedback-and-ui.md.
Update godot/core/enums.gd, godot/core/session_draw.gd, godot/core/scoring.gd,
godot/autoload/game_flow.gd, godot/autoload/save_service.gd, and godot/ui/world_ui.gd to:
1. Add Main Menu buttons: Play, Settings, Credits, Quit (with confirmation -> get_tree().quit()).
2. Add 3-area Routine Picker (Full Upper-Body Reset, Arms & Shoulders, Back & Posture)
   + Duration selector (3 min default, 6 min, 10 min with mid-session Zen Breather) + optional skippable 15s Warm-Up.
3. Add Dojo Mastery Rank (Novice C / Disciple B / Ronin A / Samurai S / Zen Master S+) and
   local Personal Best per Routine in SaveService (NO belt progression, NO medical/clinical copy).
4. Add Chair Type Check (Stable vs Swivel -> auto No-Trunk Mode) to calibration.
5. Add automated test AT-35 and run the full headless acceptance suite.
```

### Slice 3 — Hybrid OpenXR Hand Tracking + Dojo Audio/Visual Arcade Juice
```text
Read berkas/GodotDocs/MarkdownGuideForAIReconstruction/03-godot-build.md §4, 14-safety.md, and 15-feedback-and-ui.md.
Update godot/autoload/platform.gd, godot/main.gd, godot/safety/safety_monitors.gd, and godot/ui/world_ui.gd to:
1. Support Hybrid OpenXR Hand Tracking (XRHandTracker palm/index-tip, wrist roll, pinch, grasp)
   with automatic XRController3D fallback and Desktop Simulator compatibility.
2. Disable all UI raycasts during ROUND_PLAY (GP-ANTI-CHEAT-01).
3. Add Hand-Tracking FoV lap-drop fallback in AutoPauseMonitor (hands drop into lower lap zone then lose tracking >= 2.0 s -> auto-pause + passthrough).
4. Add Dojo Audio SFX manager (taiko/wood/bell/tea/shoji cues with streak pitch escalation) and lightweight
   unshaded 3D hit particle bursts + floating score labels so Hand Tracking feels responsive without haptics.
Run headless tests and verify zero errors.
```

### Slice 4 — Zen Dojo Environment Integration & Multi-Platform Render Budget Check
```text
Read berkas/GodotDocs/MarkdownGuideForAIReconstruction/03-godot-build.md §5.
Integrate the approved Zen Dojo .glb environment and optimized Zeno mascot (~19.9k tris) into godot/main.tscn.
Verify compliance with the mobile VR render budget (<= 200k–350k tris, <= 120 draw calls, max 1 DirectionalLight3D
with no real-time room shadows, no SSAO/SSR/fog, textures <= 2048/1024, ETC2/ASTC).
Verify exports for both PICO 4 Ultra (preset.0) and Meta Quest (preset.1).
```
