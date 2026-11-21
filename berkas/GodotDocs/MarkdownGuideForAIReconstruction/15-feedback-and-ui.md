# Feedback and UI

> Part of the spec pack (Meta Quest focus). **Section numbers are global across all gameplay files**, so a reference like §6.3 always means the same thing. See `00-gameplay-overview.md` for the index.
> Legend: **[S]** from source PDF · **[P]** proposal, tune in testing · **[V]** verify against vendor docs.

---

## 9. Feedback and UI

### 9.1 Haptics `GP-HAPTIC-01`
Via `IPlatformServices.PlayHaptic(hand, amplitude, duration)`:

| Event | Amplitude | Duration |
|---|---|---|
| Light touch / normal reach hit | 0.25 **[P]** | 30 ms |
| Forward Press click | 0.40 **[P]** | **50 ms [S]** |
| Solid boxing hit | 0.70 **[P]** | 80 ms |
| Light boxing hit | 0.20 **[P]** | 30 ms |

Unity exposes amplitude + duration, not true frequency, so "low-frequency strong" vs "soft" is approximated with these pairs. **[S]** (see assumption A7)
Add a haptics **on/off and intensity** setting (some users have reduced hand sensitivity). **[S]**

### 9.2 Audio
Soft, short sounds; no sudden loud sounds. Separate volume slider. Optional voice prompts for calibration. **[P]**

### 9.3 Visual style
Minimal UI, soft light, high contrast, large text. World-space UI at about 1.0–1.2 m, slightly below eye level. Buttons ≥ 10 cm × 5 cm at 1 m **[P]**. **[S]** (minimal interface, lower visual load)

### 9.4 Settings screen `GP-SET-01`
Hand mode, difficulty preset, target size, tempo cap, haptic strength, audio volume, rest-reminder interval (7–10 min), recalibrate, delete saved data.

### 9.5 Session cadence and reminders `GP-UI-REM-01` **[P]**

- The app **cannot remind** a user who is not wearing the headset (survey: forgetting is the top barrier). The prototype only shows a *"Suggested next break in 60 min"* text on the Results screen. A phone/desktop reminder is out of scope (see `../research/01-survey-analysis.md`).
- Settings add: **No-trunk mode** (§8.8), *Quick session (1 round)*, haptics on/off and intensity, rest-reminder interval (7–10 min).
- Main menu shows **Play Score Attack** as the primary button so the first target appears quickly (G8).

---

## Open questions

1. Do you have a Figma flow for the menus yet (the PDF links one)? If so, which screens exist?
2. Which languages must the UI support (English, Bahasa Indonesia)?
