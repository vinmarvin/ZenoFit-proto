# Feedback, Arcade Juice, UI, & Zeno Mascot (v0.4 — Zen Dojo)

> Part of the **ZenoFit AI Reconstruction Spec Pack (Godot 4.7)**. **Section numbers are global across all gameplay files**. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** source/research · **[D]** locked team decision · **[P]** tunable default · **[V]** verify on hardware.

---

## 9. Feedback & UI (Hybrid Hand Tracking + Controller)

### 9.1 Arcade Juice Without Haptics (Mandatory for Hand Tracking) `GP-JUICE-01` **[D]**
Because controller-free **Hand Tracking** has **zero haptic rumble**, every gameplay hit MUST deliver immediate multi-sensory feedback:
1. **Spatial Dojo Audio SFX + Combo Pitch Escalation:**
   - Use crisp, warm Dojo sounds (`taiko` / `makiwara` wood strike, temple bell `suzu`, water/tea pour, `shoji` slide, `furin` wind chime, wooden `hyoshigi` UI click).
   - Pitch scales gently upward with combo streak: `pitch_scale = 1.0 + min(streak, 20) * 0.025` (`1.00x` → `1.50x`), resetting softly on miss.
   - Calm loopable Zen BGM (`koto` / `shakuhachi` / ambient wind) at low background volume.
2. **Lightweight 3D Visual Feedback (Render-Budget Safe):**
   - On hit: emit `<= 30` unshaded particles (`CPUParticles3D`/`GPUParticles3D` pre-warmed at Boot) + spawn floating score text (`+150`, `x1.5!`, `SOLID!`) rising `0.15 m` over `0.6 s`.
   - On miss: soft fade-out (no harsh red flash, no screen shake).
3. **Zeno Mascot Reactions:**
   - Every `5x` / `10x` streak milestone, Zeno plays a celebratory bounce/wave animation + encouraging bubble/voice cue.

### 9.2 Controller Haptics (Active When Handheld Controllers Are Used) `GP-HAPTIC-01`
Via `Platform.play_haptic(hand, amplitude, duration)`:

| Event | Amplitude | Duration |
|---|---|---|
| Light touch / normal reach hit | `0.25` **[P]** | `30 ms` |
| Forward Press (`M06`) / Tea Pour (`M09`) | `0.40` **[P]** | `50 ms` **[S]** |
| Solid `M01` Makiwara hit | `0.70` **[P]** | `80 ms` |
| Light `M01` Makiwara hit | `0.20` **[P]** | `30 ms` |

Include a Settings toggle for Haptics ON/OFF & intensity (`0.0–1.0`).

### 9.3 World-Space UI & Menu Screens `GP-UI-01` **[D]**
- Positioned at `1.0–1.2 m` ahead, eye level to slightly below, high contrast, large readable text, buttons `>= 10 cm × 5 cm` at `1 m`.
- **Menu Interaction:** Support **Direct Poke** (index finger tip touching 3D button) AND **Air Pinch / Controller Ray Pointer** (ray pointer MUST turn OFF during `ROUND_PLAY`, per `GP-ANTI-CHEAT-01`).
- **Required Screens:**
  1. **Main Menu:** **`Play`**, **`Settings`**, **`Credits`**, **`Quit`** (shows *"Leave the Dojo?"* → `Yes / Stay` → `get_tree().quit()`), plus *Practice Mode* selector. Footer label: `"Welcome · Zen Dojo"` (replace old `"Aquatic sanctuary"` text). Badge: `"Hands tracked"` or `"Controllers active"`.
  2. **Routine Picker:** *"What would you like to focus on?"* — 3 cards with **strictly non-medical, upper-body copy** (NO *"Sores"*, NO leg/foot icons):
     - **`Full Upper-Body Reset`** — *"Balanced seated trial for neck, shoulders, arms, and back."*
     - **`Arms & Shoulders`** — *"Loosen up shoulders, arms, and wrists from desk work."*
     - **`Back & Posture`** — *"Open your chest and mobilize your upper back and neck."*
     - Plus **Duration Selector:** `3 min (Quick)` [default] · `6 min` · `10 min` + toggle `Warm-Up (15 s)`.
  3. **Settings:** Difficulty (`Gentle / Standard / Active`), Hand Mode (`Both / Left / Right`), `No-Trunk Mode`, Audio Volume (BGM / SFX), Haptics toggle & strength, Rest Reminder (`7–10 min`), `Recalibrate`, `Reset Saved Data`.
  4. **Credits:** Team roster (Group 4 · Lebah Ganteng), asset provenance credits, and Non-Medical Safety Notice.
  5. **Results:** Total Score, **Dojo Mastery Rank (`C / B / A / S / Zen Master`)**, **New Personal Best** badge, Accuracy %, Hits/Misses, Max Streak, Body Areas Covered, *"Suggested next break in 60 min"* (`GP-UI-REM-01`), *Play Again / Change Routine / Main Menu*.

### 9.4 Zeno Mascot Coach (`Floating Mascots.glb`) — Anatomical Constraints **[V]**
- Current `Floating Mascots.glb` has **no skeleton (`skins = 0`)**, rigid single-piece `Arm_L` / `Arm_R` (no elbow joint), and no fingers/wrists.
- **Implication for AI / 3D Team:**
  - Shoulder-swing, torso twist/bend, and neck yaw/roll demos (`M01, M02, M03, M04, M06, M07, M08, M10`) read cleanly on the current mesh.
  - For elbow/wrist demos (`M05` Temple Bell Pull, `M09` Tea Ceremony Pour), either attach lightweight **3D props** (teapot / rope handle) to Zeno's arm tips so wrist tilt & pull motion are clearly readable, OR split `Arm_L`/`Arm_R` into `UpperArm` + `Forearm` pivots in Blender.
  - Always use the **optimized GA3 mesh (~19.9k tris)** in `godot/assets/`, never the raw `66.4k` mesh.
