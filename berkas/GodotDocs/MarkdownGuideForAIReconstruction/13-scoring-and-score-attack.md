# Scoring, Arcade Score Attack, Mastery Rank, & Progress Tracking (v0.4)

> Part of the **ZenoFit AI Reconstruction Spec Pack (Godot 4.7)**. **Section numbers are global across all gameplay files**. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** source/research · **[D]** locked team decision · **[P]** tunable default · **[V]** verify on hardware.

---

## 7. Scoring and results

### 7.1 Base Hit Formulas (Preserved for `AT-07`, `AT-08`, `AT-12`)

```text
accuracy_% = 100 * hits / total_targets
timeliness = max(0, 1 - t_hit / lifetime_s)      // t_hit: seconds from spawn to hit
points_hit = 100 + floor(50 * timeliness)        // [P] speed/rhythm bonus (Level A)
lifetime_s = L_beats * (60 / BPM)
```
(`M01` Makiwara Strikes §6.1: `+25` bonus for a **solid** hit `v >= 0.30 m/s` **[P]**. Other mechanic bonuses are in their own files.)

**Simple problem (`AT-07`).** BPM = 60, `L = 2 beats` → `lifetime = 2.0 s`. Hit at `0.5 s`: `timeliness = 0.75` → `points = 100 + floor(50 * 0.75) = 137`.
**Case study (`AT-08`).** 5-target round (hit 0.4s, hit 1.0s, miss, hit 0.2s, hit 1.8s): base total = `515`, accuracy = `80%`, combo round score = `526`.

### 7.2 Level A vs. Level B Scoring Safety Rules **[D]**
- `GP-SCORE-01` Score MUST depend only on valid upper-body / mechanic-specific interactions (never on lower-body movement). **[S]**
- `GP-SCORE-02` Missed targets give `0` points and reset streak to `0`, but MUST NEVER subtract points or trigger a harsh game-over. **[P]**
- `GP-SCORE-03` Wrong-hand touches are ignored.
- `GP-SCORE-07` **Safety Split (Arcade Speed vs. Precision):**
  - **Level A mechanics (`M01, M02, M03, M05, M06, M07, M09`)** reward rhythm/timeliness and solid movement.
  - **Level B mechanics (`M04` Bokken Guard, `M08` Zen Horizon Watch, `M10` Bamboo Sway)** MUST NEVER award speed bonuses—only **precision and smoothness bonuses** (e.g., `M08` `+10` smoothness bonus only if head angular speed stayed `<= 60 deg/s` throughout the scan).

### 7.3 Combo Multiplier & Session Total `GP-SCORE-04` (`AT-27`) **[D][P]**

```text
multiplier  = 1 + min(streak_before, 20) / 20          // x1.00 ... x2.00
hit points  = floor( base_points * multiplier )
streak      : +1 on a hit, reset to 0 on a miss; CARRIES OVER across rounds in Score Attack
round score = sum of hit points;   session score = sum of all round scores
```
**Simple problem (`AT-27`).** `streak_before = 10`, `base = 137` → `multiplier = 1.50` → `floor(137 * 1.50) = 205`.

### 7.4 Dojo Mastery Rank & Personal Best `GP-RANK-01` (`AT-35`) **[D]**

Instead of a belt progression system (dropped for Week 14 scope), every completed session awards a **Dojo Mastery Rank** computed from `accuracy_%` and `hits` (for a 5-round Quick Trial; scales proportionally for Extended sessions):

| Dojo Mastery Rank | Code | Criteria **[P]** |
|---|---|---|
| **Zen Master** | `S+` | `accuracy >= 92%` AND `hits >= 25` (per 5-round stage) |
| **Samurai** | `S` | `accuracy >= 85%` AND `hits >= 20` |
| **Ronin** | `A` | `accuracy >= 75%` |
| **Disciple** | `B` | `accuracy >= 60%` |
| **Novice** | `C` | `< 60%` (still encouraging — never punitive) |

- **Personal Best (`personal_bests`):** Stored locally in `user://settings.json` or `user://sessions.json` keyed by `routine_id` (`FULL_UPPER_BODY`, `ARMS_AND_SHOULDERS`, `BACK_AND_POSTURE`) + `duration_minutes` (`3`, `6`, `10`). If `session_score > previous_best`, display a **`NEW PERSONAL BEST!`** badge on the Results screen.

### 7.5 Results Screen & Local Progress Tracking `GP-RES-01` / `GP-PROG-01` **[S][D]**
- **Results Screen shows:** Total Score, **Dojo Mastery Rank (`C/B/A/S/Zen Master`)**, **New Personal Best badge** (if beaten), Accuracy %, Hits/Misses, Max Streak, Duration, Routine name & Difficulty, **Body Areas Covered** tick list (*Neck & shoulders / Back & posture / Chest & arms — no health claims*, `GP-SCORE-06`), and buttons: *Play Again*, *Change Routine*, *Main Menu*.
- **Persistence:** Append each session locally to `user://sessions.json` (last 10 sessions) + update `personal_bests` locally. No cloud, no network.

---

## Tunables

| Parameter | Default |
|---|---|
| Base points per hit | `100` **[P]** |
| Max timeliness bonus (Level A) | `50` **[P]** |
| `M01` solid-hit bonus (`v >= 0.30 m/s`) | `25` **[P]** |
| Combo cap | `20 hits (x2.0)` **[P]** |
| Sessions kept in history list | `last 10` **[P]** |
| Rank thresholds (`S+ / S / A / B / C`) | `92% / 85% / 75% / 60% / <60%` **[P]** |
