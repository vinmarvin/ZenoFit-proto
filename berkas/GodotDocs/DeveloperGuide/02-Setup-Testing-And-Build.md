# 02 — Setup, Testing, Desktop Simulator & Android OpenXR Build

> **Project Config:** [`godot/project.godot`](../../../godot/project.godot), [`godot/export_presets.cfg`](../../../godot/export_presets.cfg), [`godot/openxr_action_map.tres`](../../../godot/openxr_action_map.tres).

---

## 1. Prerequisites & Environment

- **Godot Engine:** `Godot 4.7.2.stable` (Standard/GDScript build) with official Export Templates installed at `~/.local/share/godot/export_templates/4.7.2.stable`.
- **OpenXR Vendors Plugin v4:** Bundled under `godot/addons/godotopenxrvendors/` (`Meta Quest` + `PICO XR` Android OpenXR features enabled).
- **Local Android Build Toolchain (Pre-Configured):** `.android-build-tools/` provides `jdk17/`, `sdk/`, and `debug.keystore`, used automatically by the PICO and Quest build scripts.
- **OpenXR Action Profiles (`openxr_action_map.tres`):**
  - `/interaction_profiles/bytedance/pico4_controller`
  - `/interaction_profiles/bytedance/pico4s_controller` (PICO 4 Ultra)
  - `/interaction_profiles/oculus/touch_controller` (Meta Quest 2 / 3 / 3S)
  - `/interaction_profiles/khr/generic_controller`
  - `/interaction_profiles/ext/hand_interaction_ext`

---

## 2. Running Headless Tests & Scene Boot Verification

Run the automated 75-assertion headless test suite from `/home/ramirez/XR-FP`:

```bash
godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
```

Expected output ends with:
```text
TOTAL PASSED: 75 | TOTAL FAILED: 0
```

Verify full `main.tscn` and autoload boot cleanly without XR hardware:

```bash
godot --headless --xr-mode off --path godot --quit-after 2
```

> **Note for Sandbox Runs:** If `~/.local/share` is read-only inside an isolated terminal sandbox, `SaveService` automatically falls back to `/tmp/zenofit_userdata/` without failing persistence.

---

## 3. Running in Desktop Simulator Mode (Linux)

Launch `godot/main.tscn` directly in the Godot editor (`F5`) or CLI without a headset (`godot --xr-mode off --path godot`). When `Platform.is_xr_active == false`:
- `xr_camera.fov` sets to **`50.0°`** for crisp desktop monitor framing (never alters OpenXR headset lenses).
- **2D helper controls** (`Desktop Simulator` bar + top-right `[Auto-Hit | Next | Pause]` strip) appear automatically; inside VR they are strictly hidden.
- Virtual left/right hand spheres auto-hide on menu screens and appear during Calibration, active rounds, or while holding `Q`/`E`.

| Input | Action in Desktop Simulator |
| :--- | :--- |
| **Left Mouse Click** | Click 3D glass UI panels directly (when neither `Q` nor `E` is held) |
| **Right Mouse Drag** or **Arrow Keys** | Rotate virtual seated camera (`yaw ±85°`, `pitch ±50°`) |
| **W / S / Z / X** | Shift head forward/back/left/right slightly inside stationary `BodyFrame` |
| **Hold Q + Mouse** / **Hold E + Mouse** | Move virtual **Left** (`Q`) or **Right** (`E`) hand sphere in 3D |
| **Mouse Wheel Up / Down** | Extend or retract hand reach depth (`0.15–0.85 m`) |
| **`[` / `]`** | Rotate simulated wrist roll (`-95° .. +95°` for **Wrist Twist**) |
| **`Tab`** | Trigger `simulate_auto_action()` on the active exercise |
| **`N`** | Advance current round timer to `0.01 s` (quick-skip round) |
| **`R`** | Simulate OpenXR `pose_recentered` event |
| **`H`** | Reset camera position (`y = 1.18 m`), look angles, and wrist roll |
| **`Esc`** | Pause during active round, or return to `MAIN_MENU` |

---

## 4. Exporting & Sideloading on VR Headsets

Both automated scripts update `editor_settings-4.7.tres` (`jdk17`, `sdk`, `debug.keystore`), install the Android Build Template if missing, export a debug APK (`com.zenofit.godot.mockup`), verify ADB authorization, and launch the app automatically.

### Option A — PICO 4 Ultra / PICO 4 (`preset.0`)
```bash
./.android-build-tools/build_and_install_pico.sh
```
- Uses export preset **`PICO 4 Ultra (Android OpenXR)`** and writes `godot/build/ZenoFit-Godot-Pico.apk` (note: `export_presets.cfg` preset default is `build/ZenoFit-Godot-Pico4Ultra.apk`; the script overrides output path to `ZenoFit-Godot-Pico.apk` cleanly).

### Option B — Meta Quest 2 / 3 / 3S (`preset.1`)
```bash
./.android-build-tools/build_and_install_quest.sh
```
- Uses export preset **`Meta Quest (Android OpenXR)`** and writes `godot/build/ZenoFit-Godot-Quest.apk`.
- Enable **Developer Mode** & **USB Debugging** in the Meta Horizon app / headset, connect via USB-C, and accept **"Allow USB debugging"** inside the headset before running.
