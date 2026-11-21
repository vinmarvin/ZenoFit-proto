# Body Frame and Calibration

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 3. Coordinate frame: BodyFrame

All gameplay positions are expressed in **BodyFrame**, not world space.

| Axis | Direction |
|---|---|
| **Origin** | The user's **chest point** `C` captured in calibration. |
| **+Z (forward)** | Horizontal direction the user faces at calibration (head forward projected on the horizontal plane). |
| **+Y (up)** | World up. |
| **+X (right)** | `cross(up, forward)`. |

```csharp
public struct BodyFrame
{
    public Vector3 Origin;      // chest point C (in tracking space)
    public Quaternion Yaw;      // rotation about world-up so +Z = user forward
    public Vector3 ToWorld(Vector3 local) => Origin + Yaw * local;
    public Vector3 ToLocal(Vector3 world) => Quaternion.Inverse(Yaw) * (world - Origin);
}
```

`GP-FRAME-01` Because Tracking Origin = **Device** (no floor dependency), the BodyFrame must be rebuilt after calibration and after a recenter event.

---

## 4. Calibration

### 4.1 Purpose
Capture the user's body geometry and reach so every target is safe and reachable, and capture obstacles (desk edge, keyboard, monitor, chair armrests) so targets never appear there. **[S]**

### 4.2 Calibration steps `GP-CAL-01`

Each step shows a short instruction (text + optional voice/audio cue), has a confirm action (**trigger press**), and a *Skip / Use default* option where noted.

| # | Step | Captured data | Skippable? |
|---|---|---|---|
| 1 | **Sit comfortably, look forward** → confirm. | `SeatAnchor` = head position; `forward` yaw. | No |
| 2 | **Touch your chest** with a controller → confirm. | `C` (chest point). | Default: head − 0.25 m on Y **[P]** |
| 3 | **Touch your left shoulder, then right shoulder.** | `S_L`, `S_R` (shoulder width `W = |S_R − S_L|`). | Default `W` = 0.40 m **[P]** |
| 4 | **Reach forward with your LEFT hand as far as comfortable, no pain** → confirm. | `F_L`; `R_f,L` = forward distance from C; arm length `L_L = |F_L − S_L|`. | Per-hand skip → that hand is disabled |
| 5 | **Same with your RIGHT hand.** | `F_R`, `R_f,R`, `L_R`. | Per-hand skip → that hand is disabled |
| 6 | **Rest your hands in your lap** → confirm. | `LapPoint` (mean of both controllers). Used by auto-pause. | No |
| 7 | **Mark obstacles:** touch the desk edge, keyboard/monitor corners, and your chair armrests (several touches allowed) → confirm. | Obstacle points → exclusion spheres (§4.5). | Optional |

`GP-CAL-02` Calibration MUST be completable **seated, in under ~2 minutes** **[P]**.
`GP-CAL-03` If a hand is skipped/disabled, the app MUST switch to one-hand mode for that user. **[S]**
`GP-CAL-04` The UI MUST remind the user: "Stop if it hurts. Only reach as far as is comfortable." **[S]**
`GP-CAL-05` The user MAY redo any single step.

### 4.3 The comfort envelope and the formula

```
R_target(hand) = k × R_f,hand                 // forward distance of a target for that hand
k = reach factor, 0 < k ≤ 0.85  [S: ≤ 85 %]   // difficulty preset decides k (§5.3)
```

**Simple problem.** A user reaches forward at most **0.60 m** with the left hand. With **k = 0.85**, where is the target?
`R_target = 0.85 × 0.60 = 0.51 m` in front of the chest.
If k = 0.60 (gentle preset): `0.60 × 0.60 = 0.36 m`.

**Case study.** *Rani* is a student who sits at a desk about 10 hours a day, and her right shoulder is stiffer than her left. Calibration gives `R_f,L = 0.55 m`, `R_f,R = 0.42 m`, shoulder width `W = 0.42 m`. Standard preset, `k = 0.75`:
- Left forward target z = 0.75 × 0.55 = **0.4125 m** ≈ 0.41 m
- Right forward target z = 0.75 × 0.42 = **0.315 m** ≈ 0.32 m
The left and right targets sit at *different* depths, so each arm works within its own limit. If the app used one averaged reach instead (`(0.55 + 0.42) / 2 = 0.485 m`), both targets would sit at `0.75 × 0.485 = 0.364 m`: too close to be a useful challenge for the left arm, and further than the 0.315 m that her right arm's calibration allows.

`GP-ENV-01` A target MUST NOT be placed beyond `0.85 × R_f` of the hand that must touch it. **[S]**
`GP-ENV-02` Target height defaults to **chest (sternum) level**, `y = 0` in BodyFrame (± a small vertical jitter), *not* headset/eye height, to avoid shoulder impingement. **[S]**

### 4.4 Recenter handling `GP-CAL-06`
On a platform recenter event (`IPlatformServices.TrackingOriginRecentered`): pause the game, show "Sit comfortably and confirm", and re-run steps 1–2 only (re-derive the BodyFrame from the saved reach values). **[P]**

### 4.5 Obstacle exclusion zones `GP-CAL-07`
For each marked obstacle point `O_i` create an exclusion sphere of radius `r_ex = 0.12 m` **[P]**. A target candidate position `T` is rejected if `distance(T, O_i) < r_ex + targetRadius` for any `i`. If the spawner cannot find a valid position after N attempts, it widens the angle within the envelope, otherwise it skips the spawn and logs it (it never spawns inside an obstacle).

### 4.6 Saved data `GP-CAL-08` (local JSON)

```json
{
  "version": 1,
  "createdUtc": "2026-11-11T08:00:00Z",
  "shoulderWidthM": 0.42,
  "leftHand":  { "enabled": true,  "reachForwardM": 0.55, "armLengthM": 0.62 },
  "rightHand": { "enabled": true,  "reachForwardM": 0.42, "armLengthM": 0.52 },
  "modules": { "twistDegL": 50, "twistDegR": 40, "neckDegL": 70, "neckDegR": 65, "leanM_L": 0.30, "leanM_R": 0.20 },
  "chestOffsetFromHeadM": [0.0, -0.25, 0.08],
  "lapPointFromChestM":   [0.0, -0.45, 0.20],
  "obstacles": [ { "x": -0.30, "y": -0.30, "z": 0.00 }, { "x": 0.30, "y": -0.30, "z": 0.00 } ]
}
```
Stored under `Application.persistentDataPath`. Positions are in BodyFrame metres.

### 4.7 Module calibrations (on demand) `GP-CAL-09`

Some mechanics need one extra measurement. These run **the first time** the mechanic is drawn (or in *Recalibrate → Modules*), take ~15 s each, and are saved in the profile.

| Module | Needed by | Instruction | Captured |
|---|---|---|---|
| **Twist** | §6.4 Turret Gunner | Hold both controllers together at the chest. Turn left as far as comfortable, confirm. Then right. | `ψ_max,L`, `ψ_max,R` (yaw of the hands' midpoint in BodyFrame) |
| **Neck** | §6.8 Recon Scanner | Turn the head left as far as comfortable, confirm. Then right. | `ψ_n,L`, `ψ_n,R` (head yaw) |
| **Lean** | §6.10 Laser Evader | Hands on the rail, lean left as far as comfortable, confirm. Then right. | `Δx_max,L`, `Δx_max,R` (head lateral offset) |

`GP-CAL-10` Module values are capped (twist 60°, lean 0.25 m target offset) regardless of what the user shows. Reminder text: "Stop if it hurts."
`GP-CAL-11` **Returning-user quick check:** if a valid profile exists, the app only asks the user to sit comfortably and confirm (steps 1–2). Target ≤ 15 s **[P]** (survey: setup friction).

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Max reach factor `k` | 0.85 **[S]** | |
| Default chest offset below head (if step skipped) | 0.25 m **[P]** | |
| Default shoulder width (if step skipped) | 0.40 m **[P]** | |
| Obstacle exclusion radius `r_ex` | 0.12 m **[P]** | |
| Target calibration time budget | ~2 min **[P]** | |
| Obstacles: how many touches allowed | several **[P]** | |

## Open questions

1. Should calibration be mandatory every launch, or only on first run + when the user asks (current default)?
2. Do you want a voice narrator for the calibration steps, or text only?
3. Should upward reach (above chest) be calibrated now, or deferred?
