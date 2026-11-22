> [!WARNING]
> **DEPRECATED (Unity Build Removed in Commit `1dbc35c`):** ZenoFit is now **Godot 4.7 Only** (`godot/`), targeting **PICO 4 Ultra** and **Meta Quest 2/3/3S**. Read **`03-godot-build.md`** and **`../AGENTS.md`** instead.

# 02 — Meta Quest Configuration (Quest 2 / 3 / 3S)

> Legend: **[S]** from source PDF · **[P]** proposal · **[V]** verify against current Unity/Meta docs (menu names and versions change).
> Goal: one Unity 6 project that runs on Quest 2, 3, and 3S, with a workflow that works **even when you do not have a headset yet**.

## 1. Device matrix

| Device | SoC | Controllers | Role in this project |
|---|---|---|---|
| Meta Quest 2 | Snapdragon XR2 Gen 1 | Touch | **Performance baseline** (weakest chip). If it holds 72 FPS here, the others will. Named in the source plan **[S]**. |
| Meta Quest 3 | Snapdragon XR2 Gen 2 | Touch Plus | Named in the source plan **[S]**. |
| Meta Quest 3S | Snapdragon XR2 Gen 2 | Touch Plus | Added target. Unity documents support for Quest 2, 3, and 3S. **[V]** |

Differences that matter to this app:

| Topic | Quest 2 | Quest 3 / 3S |
|---|---|---|
| Controller interaction profile | Oculus Touch | Touch Plus **[V]** |
| Passthrough | Black-and-white | Color **[V]** |
| Performance headroom | Lowest. Design to this. | Higher |

Since the app targets one vendor, the `IPlatformServices` layer (`01-techstack.md` §3.2) now has only two implementations: `QuestPlatform` and `EditorSimPlatform`. It still earns its place: it lets you run and test everything in the Editor, and it isolates passthrough and haptics.

---

## 2. One-time project setup

Menu names are for Unity 6. **[V]**

### Step 1 — Create the project
1. Unity Hub → install **Unity 6 (6000.x)** with modules: **Android Build Support**, **OpenJDK**, **Android SDK & NDK Tools**.
2. New project from a **VR template** (URP) or blank URP. Name: `SeatedVRFitness`.
3. Commit the pinned version (`ProjectSettings/ProjectVersion.txt`).

### Step 2 — Switch platform
`File > Build Profiles` → **Android** → *Switch Platform*.

### Step 3 — Install packages
`Window > Package Manager`: install everything in `01-techstack.md` §2.1 plus **Unity OpenXR: Meta** and **AR Foundation** (§2.2). Import the XRI samples **Starter Assets** and **XR Interaction Simulator**.

### Step 4 — Enable OpenXR
`Edit > Project Settings > XR Plug-in Management` → **Android tab** → tick **OpenXR**.

> **Most common beginner mistake:** enabling OpenXR on the *Standalone (PC)* tab instead of the *Android* tab. The headset build then starts as a flat 2D window.

### Step 5 — OpenXR settings (`XR Plug-in Management > OpenXR`, Android tab)

| Setting | Value |
|---|---|
| Render Mode | **Single Pass Instanced / Multiview** (whichever the plugin offers) **[V]** |
| Depth Submission Mode | Depth 16 Bit **[P]** |
| Enabled Interaction Profiles | **Oculus Touch Controller Profile** and **Meta Quest Touch Plus Controller Profile**. Touch Pro is optional. **[V]** Without the right profile, controllers won't track. |
| Features | **Meta Quest Support** (Target Devices: Quest 2, Quest 3, Quest 3S) **[V]** |
| Passthrough feature | **Meta Quest: Camera (Passthrough)** only when you build the passthrough feature (spike S-4). Follow Unity's "Unity OpenXR: Meta" passthrough documentation for the AR Session / AR Camera Manager setup. **[V]** |

### Step 6 — Player settings (`Project Settings > Player > Android`)

| Setting | Value | Why |
|---|---|---|
| Color Space | **Linear** | Standard for URP. |
| Auto Graphics API | **Off** → **Vulkan** first **[P]** | Typically the best option for current Quest hardware. OpenGLES3 can stay as a fallback. **[V]** |
| Minimum API Level | **Android 10 (API 29)** **[P]** **[V]** | Typical Quest minimum. |
| Target API Level | Automatic (highest installed) **[P]** | Needed for store builds; fine for sideloading. |
| Scripting Backend | **IL2CPP** | Required for 64-bit. |
| Target Architectures | **ARM64 only** (untick ARMv7) | |
| Active Input Handling | **Input System Package (New)** | XRI 3.x uses it. |
| Internet Access | **Not required** | NF-04. |

### Step 7 — Quality / rendering (URP)
- One quality level for Android. MSAA **4x** **[P]**. No real-time shadows, or one cheap shadow-casting light. No post-processing.
- Low-poly, simple lighting. Calm lighting is also a UX requirement **[S]**.

### Step 8 — Project Validation
`Project Settings > XR Plug-in Management > Project Validation` → **Fix All**. Re-check after installing any package.

### Step 9 — XR rig (`00_Boot.unity`)
1. Add **XR Origin (XR Rig)** with **Tracking Origin Mode = Device**. **[S]** (solves the Floor Y-offset problem)
2. Keep the rig in the Boot scene and load other scenes **additively** so it persists.
3. Each controller gets a Ray Interactor (menus) and a small **HandTip** collider (radius ≈ 0.04 m **[P]**) used by gameplay.
4. Handle the headset **recenter** event (`XRInputSubsystem.trackingOriginUpdated`): pause and re-confirm the seat (`gameplay/01-body-frame-and-calibration.md` §4.4).

### Step 10 — Scripting define and build profile
Create a **Quest** Build Profile (Android). Add scripting define `PLATFORM_QUEST`. The `Game.Platform.Quest` assembly then compiles. In the Editor, `EditorSimPlatform` is used.

---

## 3. Running on a Quest (when you have one)

1. Create or join a Meta developer account and enable **Developer Mode** through the Meta Horizon phone app. **[V]**
2. Install **adb** and, optionally, **Meta Quest Developer Hub (MQDH)**.
3. Connect via USB-C. Inside the headset, accept the *Allow USB debugging* prompt.
4. `adb devices` must list the headset as `device` (not `unauthorized`).
5. Unity: `File > Build Profiles > Android (Quest) > Build And Run`. Or build the APK and run `adb install -r SeatedVRFitness.apk`.
6. On the headset, find the app under *Library → Unknown Sources*.
7. Logs: `adb logcat -s Unity`.

**Editor testing with a headset:** Quest Link (cable) or Air Link lets you press Play in the Editor and see it in the headset. Needs a capable PC and the Meta PC app. **[V]**

---

## 4. Developing and testing WITHOUT a headset

| Tool | What it lets you test | What it can NOT tell you |
|---|---|---|
| **XRI Interaction Simulator** (Editor) | Head and controller movement with keyboard + mouse; UI pointer; calibration logic; spawning; scoring; state machine. | Real tracking, reach feel, haptics, comfort. |
| **Meta XR Simulator** **[V]** | Quest-style OpenXR behavior on desktop. | Real-device performance and comfort. |
| **EditMode unit tests** | All maths: reach, angles, BPM, scoring. | Anything involving the headset. |

**Safe to build with only simulators:** BodyFrame maths, calibration state machine, target placement, scoring, adaptive tempo, UI flow, save/load, safety timers.

**Requires a real Quest before it can be called done:** controller tracking quality, haptic feel, passthrough toggle, comfort/cybersickness (SSQ), frame rate, reach accuracy, usability tests (week 7).

**Rule:** do not run user tests with anyone who has mobility limits until the app has run on a real headset and the movements have been reviewed by a professional. **[S]**

---

## 5. Performance budget **[P]**

| Item | Budget |
|---|---|
| Frame rate | 72 FPS on Quest 2 |
| Draw calls | < 150 |
| Triangles in view | < 200 k |
| Lights | 1 directional; no real-time shadows or 1 cheap shadow |
| Transparent overdraw | Minimal (UI panels, target glows kept small) |
| Textures | ASTC, max 2048, mostly 512–1024 |
| Targets | Pooled; no per-spawn `Instantiate` |

Check with the Unity Profiler over USB and MQDH's performance tools. **[V]**

---

## 6. Spikes (small experiments to remove risk)

| ID | Spike | Headset needed? | Done when |
|---|---|---|---|
| S-1 | "Hello VR": rig + two cubes on the hands, runs in the Editor with the Interaction Simulator. | No | Cubes follow simulated controllers. |
| S-2 | Android APK builds with the Quest profile. | No to build, yes to run | APK builds; later it runs and tracks. |
| S-3 | Haptic impulse on both hands via `PlayHaptic`. | **Yes** | Both controllers vibrate; amplitude and duration respond. |
| S-4 | Passthrough toggle via `IPlatformServices` (and the fallback pause scene). | **Yes** | Toggle works on Quest 2 and/or 3/3S, or the fallback is used. |
| S-5 | Recenter event pauses the game and rebuilds the BodyFrame. | Partly (simulate event in Editor) | Pause + re-confirm flow works. |

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| App starts as a flat 2D window | OpenXR not enabled on the **Android** tab | Enable OpenXR in XR Plug-in Management → Android. |
| Black screen / immediate exit | Missing OpenXR feature, wrong Graphics API | Run Project Validation; try Vulkan; check `adb logcat -s Unity`. |
| Controllers not tracking | Interaction profile not enabled | Enable Touch / Touch Plus profiles in OpenXR settings. |
| Everything at the wrong height | Tracking origin set to Floor | Set XR Origin to **Device**; use calibration. |
| Content jumps after system *recenter* | Origin changed | Handle the recenter event and re-confirm the seat. |
| `adb devices` shows `unauthorized` | Debugging prompt not accepted | Put the headset on and accept the prompt. |
| `adb devices` is empty | Developer mode off / bad cable | Enable developer mode; use a data-capable USB-C cable. |
| Gradle / SDK / NDK / JDK errors | Android modules missing or mismatched | Reinstall Android modules via Unity Hub; avoid external SDK/JDK paths unless required. |
| No vibration | Haptic action not mapped or profile mismatch | Check the haptic output action and enabled profile. |
| App absent from library | Looking in the wrong place | Library → *Unknown Sources*. |

---

## 8. Week-1 definition of done (no headset required)

- [ ] Unity 6 project with Android as the active platform.
- [ ] OpenXR enabled on the Android tab; Touch and Touch Plus profiles enabled.
- [ ] Player settings from §2 Step 6 applied.
- [ ] XR Origin (Device mode) in `00_Boot`; works with the Interaction Simulator (S-1).
- [ ] Quest-profile APK **builds successfully** (S-2).
- [ ] A plan and date for getting a real Quest (`00-README.md` Risk 1).
