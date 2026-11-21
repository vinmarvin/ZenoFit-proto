# Scoring, Score Attack, Results, and Progress Tracking

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 7. Scoring and results

### 7.1 Formulas

```
accuracy_% = 100 × hits / total_targets
timeliness = max(0, 1 − t_hit / lifetime_s)      // t_hit: seconds from spawn to hit
points_hit = 100 + floor(50 × timeliness)        // [P] speed/rhythm bonus
lifetime_s = L_beats × (60 / BPM)
```
(Asteroid Brawler §6.1: `+25` bonus for a **solid** hit **[P]**. Other mechanic bonuses are in their own files.)

**Simple problem.** BPM = 60, `L = 2 beats` → `lifetime = 2 × 1.0 = 2.0 s`. A target is hit after 0.5 s:
`timeliness = 1 − 0.5/2.0 = 0.75`; `points = 100 + floor(50 × 0.75) = 100 + 37 = 137`.

**Case study.** One short round of 5 targets at 60 BPM, `lifetime = 2.0 s`:

| Target | Result | `t_hit` | timeliness | Points |
|---|---|---|---|---|
| 1 | Hit | 0.4 s | 0.80 | 100 + 40 = **140** |
| 2 | Hit | 1.0 s | 0.50 | 100 + 25 = **125** |
| 3 | Miss | — | — | **0** |
| 4 | Hit | 0.2 s | 0.90 | 100 + 45 = **145** |
| 5 | Hit | 1.8 s | 0.10 | 100 + 5 = **105** |

Total = 140 + 125 + 0 + 145 + 105 = **515 points**; `accuracy = 100 × 4 / 5 = 80 %`.

### 7.2 Rules
- `GP-SCORE-01` Score MUST depend only on hand/arm interactions. No input from head position, posture, or lower body. **[S]**
- `GP-SCORE-02` Missed targets give 0 points but MUST NOT remove points or trigger a harsh fail state. **[P]**
- `GP-SCORE-03` Wrong-hand touches are ignored.

### 7.3 Results screen `GP-RES-01` **[S]**
Show: score, accuracy %, number of hits/misses, **duration**, exercise name and difficulty. Show a calm "well done" message (not a rank/leaderboard). Offer *Play again*, *Change exercise*, *Menu*.

### 7.4 Progress tracking `GP-PROG-01` **[S]**
Append each session to `sessions.json` (local): date, exercise, difficulty, hand mode, duration, hits, misses, accuracy, score, max tempo reached. Show a simple history list (last N sessions) in the menu. No cloud. **[S]**

### 7.5 Score Attack: combo multiplier and session total `GP-SCORE-04` **[D][P]**

```
multiplier = 1 + min(streak_before, 20) / 20          // ×1.00 … ×2.00
hit points = floor( base_points × multiplier )
streak     : +1 on a hit, reset to 0 on a miss (no points are removed)
round score = sum of hit points;   session score = sum of the 5 round scores
```
**Simple problem.** A hit worth 137 base points is made with `streak_before = 10`: `multiplier = 1 + 10/20 = 1.5` → `floor(137 × 1.5) = floor(205.5) = 205`.

**Case study.** The 5-target round from §7.1 (hit, hit, miss, hit, hit) with base points 140, 125, 0, 145, 105:
- Hit 1: streak 0 → ×1.00 → 140
- Hit 2: streak 1 → ×1.05 → `floor(125 × 1.05) = 131`
- Miss: 0 points, streak resets to 0
- Hit 4: streak 0 → ×1.00 → 145
- Hit 5: streak 1 → ×1.05 → `floor(105 × 1.05) = 110`
Round score = 140 + 131 + 0 + 145 + 110 = **526** (versus 515 without combo).

`GP-SCORE-05` Combo and score depend only on hits. Posture/lean never changes the score. **[S]**
`GP-SCORE-06` The Results screen also shows **which body areas** the session covered (Neck & shoulders / Back / Chest & arms) as a simple tick list. No health claims. **[P]**

---

## Tunables (edit "Your value" to be more specific)

| Parameter | Default | Your value |
|---|---|---|
| Base points per hit | 100 **[P]** | |
| Max timeliness bonus | 50 **[P]** | |
| Asteroid Brawler solid-hit bonus | 25 **[P]** | |
| Combo cap | 20 hits (×2.0) **[P]** | |
| Sessions kept in history list | last 10 **[P]** | |

## Open questions

1. Should the results screen show a simple star rating or only numbers?
2. Is comparing sessions over time (a chart) needed, or only a list?
