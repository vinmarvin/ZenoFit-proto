# Research 01 — ZenoFit Survey Analysis

> Source: "ZenoFit - Form Responses" (Google Form export, 10–11 Nov 2026) as pasted into the chat (pandas `describe()` output + first 5 rows).
> Legend: **[F]** fact computed from the data · **[I]** inference (derived, explained) · **[P]** proposal · **[V]** verify.

## 1. What this data can and cannot tell you

| Item | Status |
|---|---|
| Responses | **8** (`count = 8`) **[F]** |
| Rows visible to the analyst | **5 of 8** (rows 0–4). Rows 5–7 are known only through summary statistics. |
| Audience | Mostly ITS students and peers (4 of 8 are students; others: software developer, office worker, and one more category) **[F]**. This is a convenience sample, so expect bias toward people who already like games and VR. |
| Concept text | Questions 8 and 11 refer to "the concept above". The concept text is not in the export, so the interest rating depends on wording you cannot see here. |
| Precision | With n = 8, every percentage has a very wide margin (see §5). Treat the numbers as **directional**, not as proof of demand. |

**Privacy:** the raw file contains names and student IDs (NRP). Do **not** commit the CSV to Git or paste it into spec files. Use anonymous IDs (R1–R8) as below, and keep the raw file outside the repository.

**To get exact tables:** upload the CSV (or the 3 hidden rows) and I can compute every per-question frequency. Until then, anything about rows 5–7 below is derived from summary statistics only.

---

## 2. Facts available for all 8 responses (from summary statistics)

| Question | What the summary shows | Confidence |
|---|---|---|
| Q1 Occupation | 3 categories; **students = 4 of 8** | **[F]** |
| Q2 Hours sitting per day | 3 categories; **"8–12 h" = 6 of 8**; R1 reports more than 12 h; one respondent in a third category | **[F]** / **[I]** |
| Q3 Break frequency | 3 categories; **"rarely (only when tired/remembered)" = 4 of 8**; R3 and R5 "every 2–3 h"; R4 "every 1 h" | **[F]** |
| Q4 Body pain | 7 distinct answers; **"no complaints" = 4 of 8** | **[F]** |
| Q6 Barrier | "Forgot / nobody reminds me" is the most common exact answer (3 of 8 as a standalone answer; also inside combined answers) | **[F]** |
| Q7 VR experience | 3 categories; **"have tried" = 5 of 8** | **[F]** |
| Q8 Interest (1–5) | mean **3.875**, SD **0.991**, min 2, max 5, median 4 | **[F]** |
| Q11 Comments | 5 of 8 wrote a comment (all different) | **[F]** |

**Derived rating distribution [I].** Visible ratings are 4, 5, 4, 4, 3 (sum 20). The mean 3.875 gives a total of 31, so the three hidden ratings sum to 11. The minimum is 2, so one hidden rating is 2 and the other two sum to 9. With a maximum of 5, they must be 4 and 5.
Full distribution: **5 → 2 people, 4 → 4, 3 → 1, 2 → 1.** Check: `mean = (10 + 16 + 3 + 2) / 8 = 3.875`, sample SD = 0.991, quartiles 3.75 / 4 / 4.25. All match the summary statistics. So **6 of 8 rated 4 or 5**, and one respondent rated 2.

---

## 3. Visible respondents, anonymized (R1–R5)

| ID | Occupation | Hours | Breaks | Pain areas | Barrier(s) | Tried VR | Interest | Top features (max 3) | Stretch needs | Comment |
|---|---|---|---|---|---|---|---|---|---|---|
| R1 | Student | > 12 h | Rarely | Neck, shoulder, lower back, wrist/fingers, eyes | Forgot / no reminder | Yes | 4 | Reminder timer, hand tracking, light scoring | Wrist (anti-RSI) | A vague concern ("worried it won't work") |
| R2 | Student | 8–12 h | Rarely | None | Lazy / don't want to sweat | Yes | 5 | Light scoring | Neck and shoulder, eye relax | — |
| R3 | Student | 8–12 h | Every 2–3 h | None | Forgot, lazy, no desk space, awkward being seen | Yes | 4 | Passthrough, light scoring | Neck and shoulder, back, wrist | Good idea, but few people own VR |
| R4 | Software dev | 8–12 h | Every 1 h | Shoulder, lower back | Forgot, afraid to break focus | Yes | 4 | Passthrough, reminder timer, relaxing audio | Neck and shoulder | — |
| R5 | Office worker | 8–12 h | Every 2–3 h | Eyes | Forgot | **No** | 3 | Reminder timer, hand tracking | Eye relax | Accessibility matters; even if everyone had VR, the main problem is setting up VR every time |

---

## 4. Findings (visible rows only unless stated)

| # | Finding | Evidence |
|---|---|---|
| F1 | **Forgetting is the main barrier.** | "Forgot / no reminder" appears in 4 of 5 visible rows. |
| F2 | **Setup friction and VR ownership are adoption risks.** | R5 and R3 comments. 3 of 8 have not "tried" VR or are in a non-"tried" category **[F]**. |
| F3 | **Demand is preventive, not pain relief.** | 4 of 8 report no complaints **[F]**. |
| F4 | **Neck and shoulder is the most requested area.** | 3 of 5 visible rows (R2, R3, R4). Wrist 2 of 5 (R1, R3). Eyes 2 of 5 (R2, R5). Back 1 of 5 (R3). |
| F5 | **Light scoring and reminder timer are the most chosen features.** | Scoring 3 of 5 (R1, R2, R3); reminder 3 of 5 (R1, R4, R5); passthrough 2 of 5; hand tracking 2 of 5; audio 1 of 5. |
| F6 | **Social and space barriers exist.** | R3: no space around the desk, awkward if seen. R4: afraid to break focus. |
| F7 | **Interest is moderate to good, but uncertain.** | Mean 3.9 / 5; 6 of 8 rated 4–5 **[I]**. |

### Worked example: how uncertain is "6 of 8 rated 4 or 5"?

For small samples use the Wilson 95 % interval: with `p̂ = x/n`, `z = 1.96`,
`center = (p̂ + z²/2n) / (1 + z²/n)`, `half-width = z · √(p̂(1−p̂)/n + z²/4n²) / (1 + z²/n)`.

**Simple problem.** `x = 6`, `n = 8` → `p̂ = 0.75`. `z² = 3.8416`; `z²/n = 0.4802`; `z²/2n = 0.2401`.
`center = (0.75 + 0.2401) / 1.4802 = 0.669`.
`half-width = 1.96 · √(0.0234 + 0.0150) / 1.4802 = 1.96 · 0.1961 / 1.4802 = 0.260`.
Interval ≈ **41 % to 93 %**. The true share of the wider audience who rate it 4–5 could plausibly be anywhere in that range.

**Case study.** If a larger survey had `x = 22` of `n = 30` (73 %), the interval narrows to about **56 % to 86 %**. This is why the next step (§7) is more respondents, not more analysis of these 8.

---

## 5. Design implications → where they are in the spec

| Finding | Requirement | Spec location |
|---|---|---|
| F1 Forgetting | The headset app cannot remind someone who is not wearing it. Prototype: show a "next break" suggestion only. A phone/desktop companion reminder is **out of scope**; record it as the main product gap. | `gameplay/15` §9.5; `gameplay/00` §12 |
| F2 Setup friction | Session is 3 minutes; returning users skip calibration (≤ 15 s check); the first target appears within ≤ 30 s. | `gameplay/00` §1 (G7, G8); `gameplay/01` `GP-CAL-11` |
| F3 Preventive | No pain-relief or health claims. Results screen shows body areas "covered", not "treated". | `gameplay/13` `GP-SCORE-06`; `gameplay/14` §8.8 |
| F4 Neck and shoulder | Four of ten mechanics target neck and shoulders, and the balanced draw guarantees one per session. | `gameplay/00` §5.2 |
| F4 Wrist (RSI) | None of the 10 original mechanics trains the wrist. Added a **wrist pour** to Potion Brewer. Consider a dedicated wrist mechanic if one of the 10 is dropped. | `gameplay/11` §6.9 |
| F4 Eyes | Recon Scanner uses a **real-room far-look break** (passthrough). VR optics use a fixed focal distance, so do not claim eye relief inside VR **[V]**. | `gameplay/10` §6.8 |
| F5 Scoring | Score Attack with combo multiplier. | `gameplay/13` §7.5 |
| F5 Hand tracking | Deferred. Controllers are more reliable for rhythm and hold mechanics. Revisit after the core loop works. | `gameplay/00` §12 |
| F5 Passthrough | Optional P2 "Desk Mode" behind `IPlatformServices`. Also used for auto-pause. | `02-quest-config.md` S-4 |
| F6 Space and awkwardness | Small seated envelope, desk marked as an obstacle, short sessions. | `gameplay/01` §4.2 step 7 |

---

## 6. Conflicts between the survey and the original PDF

| Topic | Original PDF | Survey / draft | Resolution |
|---|---|---|---|
| Audience | Wheelchair and mobility-limited users | Desk-working gamers and students | Spec is written for the **desk audience** (your decision). Accessibility principles (calibrated range, one-hand mode, no leg movement, stop anytime) are kept. |
| Movements | 5 arm exercises | 10 mechanics, including trunk twist, side bend, neck | 10 mechanics; trunk/neck ones are **Level B** with extra safety and a No-trunk mode. |
| Side raise limit | 60°–70° | Shoulder height (≈ 90°) | Preset 60° / 75° / 90°. |
| Hand tracking | Out of scope | Requested by 2 of 5 visible rows | Still out of scope. |
| Gaze tracking | — | Recon Scanner needs it | Not available on Quest 2/3/3S **[V]**; head pointing used. |

---

## 7. Next steps (small, in order)

1. Share the full CSV (without names/IDs) or the 3 hidden rows so exact frequencies can be computed.
2. Add the **concept description** you showed respondents to this file, so ratings can be interpreted.
3. Collect more responses from people **outside your course** (target ≥ 30 within the desk-worker/gamer audience).
4. Add two questions: "Would you do a 3-minute session during a break?" and "Do you own a headset?" (ownership is a stronger signal than "tried").
5. Follow up R1's vague concern ("worried it won't work") with one question: *what exactly could go wrong?*
6. Use the headset tests (week 7) to measure what surveys cannot: SSQ, enjoyment, time-to-first-target.
