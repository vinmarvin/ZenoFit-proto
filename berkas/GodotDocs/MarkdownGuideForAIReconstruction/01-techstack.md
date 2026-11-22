> [!WARNING]
> **DEPRECATED (Unity Build Removed in Commit `1dbc35c`):** ZenoFit is now **Godot 4.7 Only** (`godot/`). Do NOT use this Unity file for new code. Read **`03-godot-build.md`** and **`../AGENTS.md`** instead.

# 01 — Tech Stack (Meta Quest, Unity build)

> This file describes the **Unity** build (primary). The Godot test build is in `03-godot-build.md`. Both follow the same spec and the same acceptance tests.

> Part of the spec pack. Legend: **[S]** from source PDF · **[P]** proposal · **[V]** verify against vendor docs.

## 1. Stack at a glance

| Layer | Choice | Notes |
|---|---|---|
| Engine | **Unity 6 (6000.x)** | Pin one exact version for the whole team. |
| Language | **C#** | |
| XR API | **OpenXR** (Unity OpenXR Plugin) | No Oculus XR Plugin. |
| XR interaction | **XR Interaction Toolkit 3.x** | Rig, controllers, UI pointer, haptics. |
| Input | **Input System** package | Active Input Handling = *Input System Package (New)*. |
| Render pipeline | **URP** | Mobile-friendly; use the Unity 6 VR template as a starting point **[V]**. |
| Headsets | **Meta Quest 2 / 3 / 3S** | Standalone Android apps (Meta Horizon OS). Quest is the only target. |
| UI/UX design | **Figma** **[S]** | |
| 3D assets | Blender / Unity assets **[S]** | Low-poly, mobile budget. |
| Version control | **GitHub** **[S]** + Git LFS | |

---

## 2. Packages

### 2.1 Required

| Package | ID | Version policy | Why |
|---|---|---|---|
| XR Plug-in Management | `com.unity.xr.management` | Latest compatible with Unity 6 | Enables OpenXR on Android. |
| OpenXR Plugin | `com.unity.xr.openxr` | **≥ 1.14** **[V]** | Core OpenXR runtime integration. |
| XR Interaction Toolkit | `com.unity.xr.interaction.toolkit` | **3.x** | XR Origin, interactors, haptics, UI. |
| Input System | `com.unity.inputsystem` | Latest compatible | Controller actions. |
| Universal RP | `com.unity.render-pipelines.universal` | Matches Unity 6 | Rendering. |
| TextMeshPro | built in (`com.unity.ugui`) | | Readable UI text. |
| Unity Test Framework | `com.unity.test-framework` | | EditMode tests for maths. |

### 2.2 Quest-specific

| Package | Used for | Version policy |
|---|---|---|
| **Unity OpenXR: Meta** `com.unity.xr.meta-openxr` | Quest-specific OpenXR features (e.g. passthrough via AR Foundation). | **≥ 2.1** **[V]** (Unity documents feature parity with the Oculus plugin from OpenXR 1.14 + Meta 2.1). |
| **AR Foundation** `com.unity.xr.arfoundation` | Passthrough camera access on Quest. | **6.x** **[V]** |


### 2.3 Optional dev tools

| Tool | Purpose |
|---|---|
| XRI **Interaction Simulator** (package sample) | Simulate head + controllers with keyboard/mouse in the Editor. |
| **Meta XR Simulator** | Simulate Quest in the Editor/desktop. **[V]** |
| Meta Quest Developer Hub / adb | Install builds, read logs on device. |

### 2.4 Explicitly NOT used

| Not used | Reason |
|---|---|
| Oculus XR Plugin | The source plan chose OpenXR **[S]**, and Unity documents OpenXR as the recommended long-term path (feature parity from OpenXR 1.14 + Meta 2.1). One XR path keeps things simple. |
| Meta XR All-in-One SDK | Not needed; avoids a second integration path. |
| XR Hands / hand tracking | Out of scope **[S]**. |
| Any networking, cloud, analytics, ads SDK | Out of scope **[S]**; no internet permission. |
| Heart-rate / Bluetooth sensor libraries | Out of scope **[S]**. |

---

## 3. Unity project structure **[P]**

```
Assets/
└─ _Project/
   ├─ Scenes/
   │   ├─ 00_Boot.unity            // XR rig + persistent services, loads others additively
   │   ├─ 01_MainMenu.unity
   │   ├─ 02_Calibration.unity
   │   ├─ 03_ExerciseSelect.unity
   │   ├─ 04_Gameplay.unity
   │   └─ 05_Results.unity
   ├─ Scripts/
   │   ├─ Core/            // GameFlow, Session, Settings, EventBus
   │   ├─ Calibration/     // CalibrationFlow, BodyFrame, ComfortProfile
   │   ├─ Exercises/       // ExerciseBase + 5 exercise classes
   │   ├─ Targets/         // Target, TargetSpawner, HitDetector
   │   ├─ Scoring/         // ScoreCalculator, AccuracyTracker, AdaptiveTempo
   │   ├─ Safety/          // AutoPause, RestReminder, LeanMonitor
   │   ├─ Feedback/        // Haptics, Audio, Visual cues
   │   ├─ UI/
   │   ├─ Persistence/     // JSON save/load
   │   └─ Platform/
   │       ├─ IPlatformServices.cs
   │       ├─ EditorSimPlatform.cs     // always compiled; used in Editor/simulator
   │       └─ Quest/                   // asmdef: define constraint PLATFORM_QUEST
   ├─ Prefabs/
   ├─ ScriptableObjects/   // ExerciseConfig, DifficultyPreset
   ├─ Art/   Audio/   Materials/
   └─ Tests/
       ├─ EditMode/        // pure maths tests
       └─ PlayMode/
```

### 3.1 Assembly definitions (important)

| asmdef | References | Define constraint |
|---|---|---|
| `Game.Core` | none | none |
| `Game.Gameplay` | `Game.Core`, XRI, Input System | none |
| `Game.Platform` | `Game.Core` | none |
| `Game.Platform.Quest` | `Game.Platform`, Unity OpenXR: Meta, AR Foundation | `PLATFORM_QUEST` |
| `Game.Tests.EditMode` | `Game.Core`, `Game.Gameplay` | Test assemblies |

Why: a `Define Constraint` means Quest-specific code *only compiles* in device builds. The Editor/simulator setup and unit tests never depend on Quest APIs.

### 3.2 The platform interface **[P]**

```csharp
public enum Hand { Left, Right }

public interface IPlatformServices
{
    string DeviceName { get; }
    bool SupportsPassthrough { get; }

    void Initialize();
    void SetPassthrough(bool enabled);              // no-op if unsupported
    void PlayHaptic(Hand hand, float amplitude01, float durationSeconds);
    event System.Action TrackingOriginRecentered;   // fires when the user recenters the headset
}
```

- Two implementations: `QuestPlatform` (device builds) and `EditorSimPlatform` (Editor/simulator), selected at startup by a `PlatformServicesFactory` using `#if PLATFORM_QUEST / UNITY_EDITOR`.
- Gameplay code gets it via dependency injection or a single service locator, never by `new`-ing a vendor class.

---

## 4. Coding conventions

| Topic | Rule |
|---|---|
| Naming | PascalCase types/methods, `_camelCase` private fields, `I`-prefix interfaces. |
| Architecture | Plain C# classes for logic, thin `MonoBehaviour`s for scene glue. |
| Config | All tunables in ScriptableObjects (`DifficultyPreset`, `ExerciseConfig`). **[P]**-tagged numbers are defaults there. |
| Events | A small `EventBus` (or C# events) for `TargetHit`, `TargetMissed`, `SessionPaused`, `RestDue`. |
| Update loop | No allocations in `Update`; reuse objects (target pooling). Never use `Find*` per frame. |
| Time | Use `Time.deltaTime` / `Time.unscaledDeltaTime` for pause-safe timers. Pausing must not drift the beat clock. |
| Logging | `Debug.Log` behind a `LOG` define; `adb logcat -s Unity` reads it on device. |
| Tests | Every formula in `gameplay/` (§4.3, §6.1–6.10, §7.1, §7.5, §8) has an EditMode test; see `gameplay/16-acceptance-tests.md`. |

---

## 5. Git / GitHub **[P]**

- Use Unity's standard `.gitignore` (ignore `Library/`, `Temp/`, `Logs/`, `obj/`, `Builds/`, `UserSettings/`).
- **Commit** `Packages/manifest.json` and `Packages/packages-lock.json` so everyone gets identical package versions.
- Enable **Asset Serialization = Force Text** and **Visible Meta Files**.
- Git LFS for: `*.fbx`, `*.blend`, `*.png`, `*.jpg`, `*.wav`, `*.mp3`, `*.ogg`, `*.psd`.
- Branches: `main` (always builds) ← `dev` ← `feature/<short-name>`. PR required into `main`.
- Never commit keystores or signing passwords; keep the Android keystore outside the repo.

---

## 6. Non-functional requirements

| ID | Requirement | Target |
|---|---|---|
| NF-01 | Frame rate stable on the weakest device (Quest 2) | **72 FPS**, no sustained drops **[P]** |
| NF-02 | No artificial camera motion (zero unintended locomotion) | Always **[S]** |
| NF-03 | Standalone APK, no PC needed at runtime | Always **[S]** |
| NF-04 | No internet permission | Always **[S]** |
| NF-05 | Data stored locally; no personal identifiers required | Always **[P]** |
| NF-06 | Readable UI: high contrast, large text, calm lighting | **[S]** (see `gameplay/15-feedback-and-ui.md`) |
| NF-07 | Build size | Under 500 MB **[P]** |

---

## 7. Definition of done for the tech stack (Week 1 target)

- [ ] Unity 6 project created from a VR template, pinned in `ProjectVersion.txt`.
- [ ] All §2.1 packages installed; `manifest.json` committed.
- [ ] asmdef structure in place; `Platform/Quest` and the Editor simulator platform compile independently.
- [ ] `IPlatformServices` + `EditorSimPlatform` working in the Editor.
- [ ] One EditMode test passes in CI or locally.
