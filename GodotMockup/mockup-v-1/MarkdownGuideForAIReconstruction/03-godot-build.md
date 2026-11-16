# 03 — Godot Build (second version for testing)

> Legend: **[S]** source/research · **[P]** proposal · **[V]** verify against current Godot / Meta docs.
> **Purpose (your decision):** keep the Unity build **and** add a Godot build, so both can be tested on a Quest and compared. This is a **parallel build**, not a migration.

## 1. Reality check (read this first)

| Fact | Consequence |
|---|---|
| There is **no converter** from Unity to Godot. Scenes, prefabs, C# scripts, and XR packages do not transfer. | It is a **rewrite guided by the spec**, using the Unity code only as a reference for logic. |
| The spec pack is engine-agnostic: formulas, numbers, and acceptance tests (`gameplay/16`) do not depend on the engine. | This is why the same tests can be run against both builds. |
| 10 mechanics + two engines in 8 weeks, with no headset yet. | **Port only the P0 slice first** (calibration + Score Attack loop + M01, M06, M07). Expand only if time allows. |
| A/B testing needs a real Quest. | Simulator results do not count for the comparison. |

**Honest recommendation:** finish a Unity vertical slice first, freeze the numbers in the tests, then port the same slice to Godot. Starting both at once doubles the number of unknowns.

## 2. Decisions for the Godot build

| ID | Decision | Notes |
|---|---|---|
| G-01 | Godot **4.6 or newer** (check current stable) **[V]** | From 4.6 the OpenXR Vendors plugin is optional but recommended; Godot can export to most Android XR devices directly. The plugin unlocks vendor features and may be needed for store releases. |
| G-02 | Language: **GDScript** | Best-supported path. C# on Android export has been experimental in Godot 4.x **[V]**, so avoid it even though you know C#. |
| G-03 | Renderer: **Compatibility (OpenGL)** | Godot's docs advise it for Android XR for now; the Mobile Vulkan renderer is still being polished **[V]**. |
| G-04 | XR API: **OpenXR**, with the **Godot OpenXR Vendors plugin** installed (Meta features, passthrough). | Passthrough on Quest needs the vendors plugin v3.0.0 or later **[V]**. |
| G-05 | Same package concept, **different Android package name** from the Unity build. | Lets both builds be installed side by side on one Quest. |
| G-06 | Tests: **GUT** (or gdUnit4) for the pure-maths tests **[V]**. | Same numbers as `gameplay/16`. |

## 3. Concept map: Unity → Godot

| Unity (this spec) | Godot |
|---|---|
| Scene / Prefab | Scene (`.tscn`), instanced as a node |
| `MonoBehaviour` | `Node` with a GDScript attached |
| `ScriptableObject` (`DifficultyPreset`, `ExerciseConfig`) | `Resource` (`.tres`) with `@export` fields |
| XR Origin (Device tracking origin) | `XROrigin3D` + `XRCamera3D`; OpenXR **Reference Space = Local** (head-centred) **[V]** |
| XR controllers (XRI) | `XRController3D` nodes (`left_hand`, `right_hand` trackers) |
| Input System actions | OpenXR **Action Map** (`openxr_action_map.tres`) |
| Controller haptics | `XRController3D.trigger_haptic_pulse(action, frequency, amplitude, duration, delay)` **[V]** |
| Collider (trigger) / Layers | `Area3D` + `CollisionShape3D` / collision layers and masks |
| Recenter event (`trackingOriginUpdated`) | `OpenXRInterface.pose_recentered` signal |
| Passthrough (AR Foundation + Meta feature) | OpenXR **environment blend mode** (alpha blend) + vendors plugin |
| Coroutines / C# events | `await` + signals |
| `Application.persistentDataPath` JSON | `user://` + `FileAccess` + `JSON` |
| Assembly definitions | Folders / autoloads (no equivalent) |
| Build Profiles | **Export presets** (one per device) |
| `IPlatformServices` | An autoload `platform.gd` with two implementations (Quest, DesktopSim) |

### 3.1 Two traps that will silently break the numbers

**1. Coordinate handedness.** Unity is left-handed with **+Z forward**. Godot is right-handed with **−Z forward**. The spec uses `+Z forward` (BodyFrame). Keep spec math in *spec space* and convert only at the boundary:

```gdscript
# spec space (x right, y up, z forward) -> Godot space
static func to_godot(p: Vector3) -> Vector3:
    return Vector3(p.x, p.y, -p.z)
```
**Simple problem.** A target `0.51 m` in front of the chest is `z = +0.51` in the spec. In Godot it is `z = −0.51`. If you forget, AT-01 passes in the maths test but the target appears behind the user.

**2. Yaw sign.** In the spec, positive yaw means turning **right** (clockwise from above). In Godot, positive rotation about +Y is counter-clockwise from above, so turning right is **negative**.
**Case study.** The Twist calibration records `ψ_max,R = 40°` (spec). In Godot, the right-hand target's `rotation.y` is `−40°`. If the sign is not converted, right targets appear on the left.

Put both conversions in one file (`core/spec_space.gd`) and write a test for each.

## 4. Godot project layout **[P]**

```
godot/ZenoFit/
├─ project.godot
├─ openxr_action_map.tres
├─ addons/            godotopenxrvendors/  gut/
├─ autoload/          platform.gd  game_flow.gd  event_bus.gd  save_service.gd
├─ core/              spec_space.gd  body_frame.gd  geometry.gd  scoring.gd  adaptive_tempo.gd
├─ calibration/
├─ mechanics/         m01_asteroid_brawler/ … m10_laser_evader/   (one folder per mechanic)
├─ targets/
├─ safety/
├─ ui/
├─ resources/         difficulty_presets/*.tres
├─ scenes/            boot.tscn  main_menu.tscn  session.tscn  results.tscn
└─ tests/
```
Same rule as Unity: **pure maths in `core/` with tests; scene glue stays thin.**

## 5. Setup (Quest) — step by step

Follow the current Godot "Deploying to Android" XR page for exact menu names. **[V]**

1. Install Godot 4.6+ and the Android prerequisites: **OpenJDK 17**, **Android Studio / Android SDK**, and set the SDK path in Godot's editor settings.
2. `Project > Install Android Build Template…` (creates the `android/` folder for Gradle builds).
3. Install the **OpenXR Vendors** plugin from the Asset Library (search "OpenXR vendors") and enable it.
4. `Project Settings > XR > OpenXR`: **Enabled**, Form Factor **Head Mounted**, Reference Space **Local** (seated, head-centred) **[V]**.
5. `Project Settings > Rendering`: renderer **Compatibility**; enable the XR shaders option **[V]**.
6. `Project > Export… > Add… > Android`. Name it **Meta Quest**. Enable **Use Gradle Build**, set **XR Mode = OpenXR**, and under *XR Features* select the **Meta** entry (or Khronos if no entry appears). Enable **Runnable** for one-click deploy.
7. Set a **different package name** from the Unity build (G-05) and a different app label ("ZenoFit (Godot)").
8. Enable developer mode on the Quest, connect via USB, and use **one-click deploy**. On Windows you may need Meta's ADB driver. **[V]**

### 5.1 Minimal startup script

```gdscript
extends Node3D

var xr_interface: XRInterface

func _ready() -> void:
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.is_initialized():
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        get_viewport().use_xr = true
        xr_interface.pose_recentered.connect(_on_pose_recentered)
    else:
        push_warning("OpenXR not initialized: running desktop simulator")

func _on_pose_recentered() -> void:
    # same rule as Unity: pause and ask the user to re-confirm the seat (gameplay/01 §4.4)
    pass
```

### 5.2 Scene tree for the rig

```
Main (Node3D)
├─ XROrigin3D
│   ├─ XRCamera3D
│   ├─ LeftHand  (XRController3D, tracker = left_hand)
│   │   └─ HandTip (Area3D, sphere radius ≈ 0.04 m)
│   └─ RightHand (XRController3D, tracker = right_hand)
│       └─ HandTip
└─ Session (instanced scenes go here, the "additive" equivalent)
```

### 5.3 Hit detection (same maths as `gameplay/02` §6.C)

```gdscript
static func segment_hit(p0: Vector3, p1: Vector3, centre: Vector3, radius: float) -> bool:
    var closest := Geometry3D.get_closest_point_to_segment(centre, p0, p1)
    return closest.distance_to(centre) <= radius
```
The segment test prevents tunnelling when the hand moves several centimetres per frame at 72 Hz. **[V]** (verify `Geometry3D.get_closest_point_to_segment` signature in your Godot version).

### 5.4 Platform service

```gdscript
# autoload/platform.gd
extends Node
func play_haptic(hand: String, amplitude: float, duration_s: float) -> void:
    var ctrl: XRController3D = get_tree().root.find_child(hand + "Hand", true, false)
    if ctrl:
        ctrl.trigger_haptic_pulse("haptic", 0.0, amplitude, duration_s, 0.0)
func set_passthrough(enabled: bool) -> void:
    # switch the environment blend mode (alpha blend = passthrough) via OpenXRInterface [V]
    pass
```
The action name `"haptic"` must exist in the action map. **[V]**

## 6. Testing without a headset

| Tool | Use |
|---|---|
| **Desktop simulator rig** (you build it: two `Node3D` hands moved with mouse/keyboard) | Test calibration logic, spawning, scoring, UI flow. Equivalent of Unity's EditorSim. |
| **Meta XR Simulator** | The Godot Meta Toolkit includes a setup tool that makes the editor launch the simulator on Play **[V]**. |
| **GUT tests** | All formulas in `gameplay/16`. |

Same limits as Unity: simulators cannot show tracking feel, haptics, comfort, or real frame time.

## 7. Parity matrix (fill this in as you go)

| Feature | Spec | Unity | Godot |
|---|---|---|---|
| Spec-space conversion + tests | §3.1 above | n/a | ☐ |
| BodyFrame + base calibration + save/load | `gameplay/01` | ☐ | ☐ |
| Segment hit detection | `gameplay/02` §6.C | ☐ | ☐ |
| Score Attack loop (draw, timer, results, combo) | `gameplay/00` §5, `13` | ☐ | ☐ |
| **M01** Asteroid Brawler | §6.1 | ☐ | ☐ |
| **M06** Force Blast | §6.6 | ☐ | ☐ |
| **M07** Shield Crank | §6.7 | ☐ | ☐ |
| Safety: pause, lap rest, rest reminder | `gameplay/14` | ☐ | ☐ |
| Haptics | `gameplay/15` §9.1 | ☐ | ☐ |
| Recenter handling | `gameplay/01` §4.4 | ☐ | ☐ |
| Passthrough / fallback (P2) | `02-quest-config.md` S-4 | ☐ | ☐ |
| P1 / P2 mechanics | §6.2–6.10 | ☐ | ☐ |

A mechanic is "ported" only when its acceptance tests in `gameplay/16` pass in Godot **with the same numbers**.

## 8. A/B comparison plan (week 7–8, real Quest)

Install both builds on the **same headset**, use the **same testers**, alternate the order, and measure:

| Metric | How to measure |
|---|---|
| Frame time | Frame budget `= 1000 / refresh_Hz` ms. Use Meta's OVR Metrics Tool on device **[V]**, plus the Unity Profiler / Godot performance monitors. |
| Startup time | `adb shell am start -W <package>/<activity>` prints the launch time. |
| Build size | APK size in MB. |
| Tracking/hand feel | 1–5 rating from testers (same wording for both). |
| Comfort | SSQ after each build. |
| Stability | Crashes and pauses during 10 sessions. |

**Simple problem (frame budget).** At 72 Hz the budget is `1000 / 72 = 13.89 ms`. At 90 Hz it is `1000 / 90 = 11.11 ms`.
**Case study.** If Unity averages `11.2 ms` and Godot `12.9 ms` at 72 Hz: Unity headroom `= 13.89 − 11.2 = 2.69 ms` (19 %), Godot headroom `= 13.89 − 12.9 = 0.99 ms` (7 %). Both pass, but Godot has little room for the heavier P2 scenes.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Rewrite eats the schedule | Port the P0 slice only; keep the parity matrix honest. |
| XR features differ between engines (passthrough, haptics) | Hide behind `platform.gd`; test on a real Quest early. |
| Handedness and yaw sign bugs | `spec_space.gd` + tests (§3.1). |
| C# temptation | Stay on GDScript (G-02). |
| Renderer problems on Android XR | Stay on Compatibility (G-03). |
| Comparison is unfair (different art/effects) | Use identical assets and the same spec numbers. |
