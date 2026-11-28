# [Team name] · Group Assignment 4 · Same Build, Two Headsets

**Extended Reality · Realitas X · EF234711 / EA234505 · Semester 2026/1**
**Team:** Lebah Ganteng · Group 4 · **Class:** IF
**Due:** Mon 30 Nov 2026, 23:59 WIB.

**Our promise.** On ___ (named headset and chipset) at ___ Hz, every frame of our scene must be ready in ___ ms.
**Low end.** On ___ the worst view ran at ___ FPS (App GPU time ___ ms), so the budget was **met / not met**.
**High end.** On ___ the worst view ran at ___ FPS (App GPU time ___ ms), so the budget was **met / not met**.
**Why they differ.** ___

---

## 1 · Stated budget


| Item                                                                | Our answer |
| ------------------------------------------------------------------- | ---------- |
| Target headset and chipset (the device we promise for)              |            |
| Refresh rate (Hz)                                                   |            |
| Frame time budget (ms) = 1000 ÷ Hz                                 |            |
| Scene budget (triangles or splats, and draw calls if you know them) |            |
| Share of the GA3 reconstruction and of the generated asset          |            |
| Where this budget came from (README Section 11, GA3.md 3.1, other)  |            |

---

## 2 · Test scene, path and settings

### 2.1 What we tested


| Item                                                                                  | Our answer |
| ------------------------------------------------------------------------------------- | ---------- |
| Build type (Unity APK, WebXR URL, other) and version or commit                        | APK        |
| How it was opened on the headset (installed APK, Quest Browser URL, Pico Browser URL) |            |
| Measuring tool and version (OVR Metrics Tool on Quest, Pico Metrics Tool on Pico)     |            |
| Date, place and who wore the headset (role only, no names needed)                     |            |

### 2.2 The 60 second path (identical on every device)


| Hold                                               | 20 seconds looking at | Why we chose it |
| -------------------------------------------------- | --------------------- | --------------- |
| Start view                                         |                       |                 |
| **Worst view** (most triangles or splats in sight) |                       |                 |
| Asset up close                                     |                       |                 |

### 2.3 Settings per run


| Run | Device | Refresh rate (Hz) | Foveation level | Resolution scale | Quality level | Anything else we changed |
| --- | ------ | ----------------- | --------------- | ---------------- | ------------- | ------------------------ |
| A   |        |                   |                 |                  |               |                          |
| A   |        |                   |                 |                  |               |                          |
| B   |        |                   |                 |                  |               |                          |
| B   |        |                   |                 |                  |               |                          |

> Run A is your current settings. Run B is the same path with **one** change (Section 6). If you ran more, add rows.

---

## 3 · Results per device


| Run | Device | Avg FPS | Lowest FPS | App GPU time (ms) | CPU utilisation (%) | Stale frames | Evidence file in`ga4/` |
| --- | ------ | ------- | ---------- | ----------------- | ------------------- | ------------ | ---------------------- |
| A   |        |         |            |                   |                     |              |                        |
| A   |        |         |            |                   |                     |              |                        |
| B   |        |         |            |                   |                     |              |                        |
| B   |        |         |            |                   |                     |              |                        |

> Write the stat names your tool actually shows. If a stat is not available on a device, write "not shown" instead of leaving it empty. Pico readings: say whether the CPU and GPU levels were locked.

![Overlay at the worst view, low end](ga4/low_worst.png)
*Figure 1. ___ at the worst view, run A. Date: ___.*

![Overlay at the worst view, high end](ga4/high_worst.png)
*Figure 2. ___ at the worst view, run A. Date: ___.*

---

## 4 · Verdict per device

> A budget is met only if the **worst view** holds the refresh rate. The average of a calm view does not count.


| Device | Budget (ms) | Measured at the worst view | Met or not met | Bottleneck: CPU or GPU, and the number that shows it |
| ------ | ----------- | -------------------------- | -------------- | ---------------------------------------------------- |
|        |             |                            |                |                                                      |
|        |             |                            |                |                                                      |

---

## 5 · Why the two headsets differ

> Three to six sentences. Name the cause, not the feeling. Useful causes: chipset class (XR2 Gen 1 vs XR2 Gen 2), display resolution, refresh rate, CPU or GPU bound, one heavy asset, draw calls, transparency or overdraw, splat count, shader cost, browser vs native build.

On ___ the worst view took ___ ms, but on ___ it took ___ ms, because ___.
The bottleneck on the low end headset is the ___, because ___ (number).

---

---

## 6 · One change we tested


| Item                                                                              | Our answer              |
| --------------------------------------------------------------------------------- | ----------------------- |
| The one change (foveation level, a lighter asset, resolution scale, refresh rate) |                         |
| Device it was tested on                                                           |                         |
| Before (run A) at the worst view                                                  | ___ FPS, App GPU ___ ms |
| After (run B) at the worst view                                                   | ___ FPS, App GPU ___ ms |
| What we lost (edge blur, text sharpness, detail, smoothness)                      |                         |
| Will we keep it for the Final Project? Why?                                       |                         |

---

## 7 · Limitation (required)

**Our measurement** can be trusted for ___, but not for ___, because ___.
**On the low end headset, our build still cannot** ___.

> If your build did not run on a headset at all, this section is where you earn points: the first error you saw, the first thing you tried, and exactly what was and was not measured.

---

## 8 · AI Use Statement (Level C)


| Item                               | Our answer                                                         |
| ---------------------------------- | ------------------------------------------------------------------ |
| Level                              | C (working aid, disclosed)                                         |
| Tools (name and version)           |                                                                    |
| What we used them for              |                                                                    |
| What we checked ourselves, and how |                                                                    |
| Confirmation                       | Every number in Sections 3, 4 and 6 was read from a headset by us. |

---

## Sign-off

> Each member adds their own line, ticked, **in a commit made from their own GitHub account**.

- [ ]  ___ (name, NRP) · My part was ___ · I have read this GA4.md and agree it is true · date ___
- [ ]  ___ (name, NRP) · My part was ___ · I have read this GA4.md and agree it is true · date ___
- [ ]  ___ (name, NRP) · My part was ___ · I have read this GA4.md and agree it is true · date ___
- [X]  Ryan Marvin Sirait (5025231215) · My part was Game Developer and Software Testing · I have read this GA4.md and agree it is true · date 29/11/2026.
