# Targets, Adaptive Tempo, Hit Detection, & Anti-Cheat (v0.4)

> Part of the **ZenoFit AI Reconstruction Spec Pack (Godot 4.7)**. **Section numbers are global across all gameplay files**. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** source/research · **[D]** locked decision · **[P]** tunable default · **[V]** verify on hardware.

---

## 6.A Shared rules for all mechanics

- A target has a logical **sphere/zone radius** from the active `DifficultyPreset` (`0.12 / 0.10 / 0.08 m`), rendered with Zen Dojo visual cues (color + icon/ring shape so colorblind users can tell Left vs. Right vs. Either). **[P]**
- Targets appear on a **beat** (rhythm mechanics) or sequence trigger and expire after lifetime `L` beats. Touching in time = **hit**; expiring = **miss** (0 points, resets combo streak, never removes score or triggers harsh game-over).
- All distances and vectors are computed strictly in **BodyFrame (`SpecSpace`, `+Z` forward)** and converted to Godot space only via `SpecSpace.to_godot()`.
- **Scapular Plane Guideline (Hand Tracking FoV) [D]:** Lateral/wide-arm targets (`M03`) SHOULD sit `15°–30°` forward of the coronal plane so hands remain inside the front-facing camera FoV of PICO 4 Ultra and Meta Quest while reducing shoulder impingement.

---

## 6.B Adaptive tempo (rhythm mechanics)

```text
interval_s       = 60 / BPM                 // seconds between targets
window           = last 8 targets
accuracy         = hits / targets_in_window
if accuracy >= 0.85 -> BPM += 5             (never above preset max)
if accuracy <  0.60 -> BPM -= 5             (never below 40)
otherwise           -> hold
```

**Simple problem.** At 60 BPM, `interval = 1.0 s`; at 75 BPM, `0.8 s` (`AT-05`).
**Case study.** Standard starts at 60 BPM → 87.5 % → 65 BPM → 75 % → hold 65 BPM → 50 % → 60 BPM (`AT-06`).

---

## 6.C Anti-tunnelling hit detection (shared) `GP-HIT-01`

At 72–90 Hz a fast hand can move several centimetres per frame and tunnel through a small sphere. Therefore:
1. Each frame, build the **segment** from the hand tip's previous BodyFrame position `P0` to current position `P1`.
2. Compute `closest = Geometry3D.get_closest_point_to_segment(target_centre, P0, P1)`.
3. If `closest.distance_to(target_centre) <= targetRadius + handTipRadius` → candidate hit (`AT-13`).
4. Ignore disabled hands and enforce `effective_hand_mode` (`AT-11`).

---

## 6.D Anti-Raycast & Anti-Cheat Enforcement `GP-ANTI-CHEAT-01` **[D]**

To ensure **Handheld Controllers** never degenerate into lazy wrist-flicking or laser-pointing (preserving real upper-body exercise in both Hand Tracking and Controller modes):

1. **Zero Raycasting During `ROUND_PLAY`:**
   - Ray pointers are **strictly disabled** whenever `GameFlow.current_state == ROUND_PLAY`.
   - Every target interaction MUST come from **Direct 3D Spatial Contact / BodyFrame geometry** (`XRHandTracker` palm/index-tip OR `XRController3D` physical position).
2. **Mechanic-Specific Physical Movement Gates (Verified by `AT-29`–`AT-34`):**
   - **Forward Velocity & Guard Return (`M01`):** A punch hit requires forward Z-velocity `v_z >= 0.25 m/s` (rejects holding a hand motionless in the lane), OR the hand must retract into the guard zone (`z <= 0.25 m`) between hits (`AT-29`). *(Note: `AT-12` pure speed classification `v_solid = 0.30` still passes in `MechanicsMath.m01_is_solid_hit()`.)*
   - **Span & Abduction Validation (`M03`):** Wing-level bonus (`+10 pts/s`) and valid steering require `right.x - left.x >= 0.70 * calibrated_span` and arm abduction angle within `preset.m03_abduction_theta_deg ± 15°` (`AT-30`).
   - **Head–Hand Yaw Cross-Check (`M04`):** Aim lock requires hands near chest (`||mid|| <= 0.35 m`) **AND** head yaw turning with the torso (`|head_yaw_deg - aim_yaw_deg| <= 20°`), preventing sideways arm translation with a static torso (`AT-31`).
   - **Bilateral Stroke & Timeout (`M05`):** In `BOTH_HANDS` mode, BOTH hands must start at `>= z_start - 0.06` and pull back to `<= z_end + 0.06` within `2.0 s` (`AT-32`).
   - **Retract Hysteresis (`M06`):** After a blast release + cooldown, active hand(s) must pull back behind `z_plane - 0.10 m` before a new charge can begin (`AT-32`).
   - **Signed-Angle Full Arc (`M07`):** Replace `absf(d_angle)` with **signed angular delta** matching the active `clockwise` / `counter-clockwise` direction, and validate both hands in `BOTH_HANDS` mode (`AT-33`).
   - **Over-Cup Pour Check (`M09`):** Wrist roll (`>= 60°`) only accumulates pour progress while the active hand is positioned horizontally over the moving cup/cauldron (`|hand.x - cup.x| <= 0.14 m`) (`AT-34`).
   - **Overhead Rail Hold (`M10`):** Both active hands must remain raised on the overhead bo-staff (`y_hand >= y_rail - 0.15 m`) during side bends; releasing the rail pauses the approaching wall (`AT-34`).

---

## Tunables

| Parameter | Default | Notes |
|---|---|---|
| Adaptive window size | 8 targets **[P]** | `AdaptiveTempo.DEFAULT_WINDOW_SIZE` |
| Raise / Lower tempo thresholds | `>= 0.85` / `< 0.60` **[P]** | `±5 BPM`, floor `40 BPM` |
| Hand-tip collider radius | `0.04 m` **[P]** | `ZenoGeometry.DEFAULT_HAND_TIP_RADIUS_M` |
| `M01` minimum punch forward `v_z` | `0.25 m/s` **[P]** | Blocks static-hand holding (`AT-29`) |
| `M01` guard retract `z` | `<= 0.25 m` **[P]** | Required between consecutive punches |
| `M03` minimum span ratio | `0.70` **[P]** | Blocks hands-in-front-of-stomach cheat (`AT-30`) |
| `M04` max chest distance / head-hand delta | `0.35 m` / `20°` **[P]** | Blocks arm-only sliding (`AT-31`) |
| `M06` retract hysteresis margin | `0.10 m` **[P]** | Behind `z_plane` (`AT-32`) |
| `M09` over-cup horizontal tolerance | `0.14 m` **[P]** | Blocks pouring off-target (`AT-34`) |
| `M10` overhead rail vertical tolerance | `0.15 m` **[P]** | Blocks head-only dodging (`AT-34`) |
