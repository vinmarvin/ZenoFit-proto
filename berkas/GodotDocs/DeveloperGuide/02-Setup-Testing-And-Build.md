# 02 — Setup, Testing, Multi-OS Desktop Simulator & Local VR Build

> **Project Config:** [`godot/project.godot`](../../../godot/project.godot), [`godot/export_presets.cfg`](../../../godot/export_presets.cfg), [`godot/openxr_action_map.tres`](../../../godot/openxr_action_map.tres), [`.gitignore`](../../../.gitignore).

---

## 1. Prerequisites & Repository Layout (Git-Tracked vs. Machine-Local)

### Required Software
- **Godot Engine:** **`Godot 4.7.2.stable`** (Standard / GDScript edition, **not** `.NET`).
- **Godot Export Templates:** Official `4.7.2.stable` templates (required when exporting Android APKs or desktop binaries; install from `Editor -> Manage Export Templates...`).
- **OpenXR Vendors Plugin v5.2.0:** Bundled directly in [`godot/addons/godotopenxrvendors/`](../../../godot/addons/godotopenxrvendors/) with `Meta Quest` and `PICO XR` Android OpenXR features enabled in `export_presets.cfg`.
- **OpenXR Action Profiles (`openxr_action_map.tres`):**
  - `/interaction_profiles/bytedance/pico4_controller`
  - `/interaction_profiles/bytedance/pico4s_controller` (PICO 4 Ultra)
  - `/interaction_profiles/oculus/touch_controller` (Meta Quest 2 / 3 / 3S)
  - `/interaction_profiles/khr/generic_controller`
  - `/interaction_profiles/ext/hand_interaction_ext`

### Gitignored / Machine-Local Directories
According to [`.gitignore`](../../../.gitignore), the following directories and artifacts are **not** stored in Git and are generated or installed locally on your workstation:
- `godot/.godot/` — Local Godot resource & `global_script_class_cache.cfg` cache (created on project open or `--import`).
- `godot/android/` — Gradle Android Build Template installed per machine (`Project -> Install Android Build Template...`).
- `godot/build/` & `*.apk` — Local exported APK / desktop binaries.
- `godot/export_templates/` & `.android-build-tools/` — Optional machine-local templates and portable JDK/SDK tools.

---

## 2. Opening & Running the Project (Linux, Windows, macOS)

### Option 1 — Godot Editor GUI (All Operating Systems)
1. Launch **Godot 4.7.2.stable**.
2. Click **Import** and select `<repo>/godot/project.godot`.
3. Wait for the first asset & script scan to finish, then press **`F5`** (or click **Run Project**) to launch [`main.tscn`](../../../godot/main.tscn).
4. When no OpenXR headset/runtime is connected, ZenoFit automatically launches in **Desktop Simulator** mode.

### Option 2 — Command Line (Per-OS)

Run from the repository root (`XR-FP/`):

#### Linux
```bash
godot --headless --xr-mode off --path godot --import
godot --xr-mode off --path godot
```

#### Windows (PowerShell)
Use **`Godot_v4.7.2-stable_win64_console.exe`** (or add Godot to `PATH`) so logs and test summaries print to PowerShell (`*_win64.exe` detaches console output). `project.godot` uses `gl_compatibility` (with `rendering_device/driver.windows="d3d12"` configured).
```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --xr-mode off --path godot --import
.\Godot_v4.7.2-stable_win64_console.exe --xr-mode off --path godot
```

#### macOS (Apple Silicon & Intel)
Desktop Simulator, headless acceptance tests, and Android APK export/sideloading via ADB all run natively on macOS (standalone VR builds are tested on the headset via ADB).
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --xr-mode off --path godot --import
/Applications/Godot.app/Contents/MacOS/Godot --xr-mode off --path godot
```

---

## 3. Running Automated Headless Tests & Local Save Paths

### Step A — Refresh the Class Cache (Fresh Clones / New Scripts)
Always run `--import` once on a fresh checkout or after pulling commits that add new `class_name` scripts so `godot/.godot/global_script_class_cache.cfg` stays current.

### Step B — Run the 101-Assertion Acceptance Suite & Boot Check

#### Linux
```bash
godot --headless --xr-mode off --path godot --import
godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
godot --headless --xr-mode off --path godot --quit-after 2
```

#### Windows (PowerShell)
```powershell
.\Godot_v4.7.2-stable_win64_console.exe --headless --xr-mode off --path godot --import
.\Godot_v4.7.2-stable_win64_console.exe --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
.\Godot_v4.7.2-stable_win64_console.exe --headless --xr-mode off --path godot --quit-after 2
```

#### macOS
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --xr-mode off --path godot --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --xr-mode off --path godot --quit-after 2
```

Expected test summary (exit code `0`, zero parse errors, zero ObjectDB leaks):
```text
TOTAL PASSED: 101 | TOTAL FAILED: 0
```

> **Sandbox Note:** If `user://` cannot be written inside an isolated terminal sandbox, `SaveService` automatically falls back to `/tmp/zenofit_userdata/` without failing persistence.

### Local `user://` Persistence Paths by OS
ZenoFit writes `calibration_profile.json`, `settings.json`, `sessions.json`, and `personal_best.json` under Godot's `user://` directory (also resettable in-app via `Settings -> Comfort -> Reset Saved Data`):
- **Linux:** `~/.local/share/godot/app_userdata/ZenoFit (Godot)/`
- **Windows:** `%APPDATA%\Godot\app_userdata\ZenoFit (Godot)\`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/ZenoFit (Godot)/`

---

## 4. Desktop Simulator Controls Reference (Linux / Windows / macOS)

When `Platform.is_xr_active == false`:
- `xr_camera.fov` sets to **`50.0°`** for comfortable monitor framing (never alters OpenXR headset lenses).
- **2D helper controls** (bottom shortcut bar + top-right `[Auto-Hit | Next | Pause]` strip during rounds) appear automatically; inside VR headsets they are strictly hidden.
- Virtual left/right hand spheres auto-hide on menu screens and appear during Calibration, active rounds, or while holding `Q`/`E`.
- On two-set exercises (`Shoulder Press`, `Bicep Curl`, `Arm Circles`, `Lateral Raise`), pressing **`Tab`** or **`Auto-Hit`** simulates 1 rep per press (or advances the `1.6 s` Set 1 -> Set 2 transition).

| Input | Action in Desktop Simulator |
| :--- | :--- |
| **Left Mouse Click** | Click 3D glass UI panels directly (when neither `Q` nor `E` is held) |
| **Right Mouse Drag** or **Arrow Keys** | Rotate virtual seated camera (`yaw ±85°`, `pitch ±50°`) |
| **W / S / Z / X** | Shift head forward/back/left/right slightly inside stationary `BodyFrame` |
| **Hold Q + Mouse** / **Hold E + Mouse** | Move virtual **Left** (`Q`) or **Right** (`E`) hand sphere in 3D |
| **Mouse Wheel Up / Down** | Extend or retract hand reach depth (`0.15–0.85 m`) |
| **`[` / `]`** | Rotate simulated wrist roll (`-95° .. +95°` for **Wrist Twist**) |
| **`Tab`** | Trigger `simulate_auto_action()` on the active exercise |
| **`N`** | Advance current round timer to `0.01 s` (quick-skip timed round) |
| **`R`** | Simulate OpenXR `pose_recentered` event |
| **`H`** | Reset camera position (`y = 1.18 m`), look angles, and wrist roll |
| **`Esc`** | Pause during active round, or return to `MAIN_MENU` |

---

## 5. Local Setup & Deployment for Standalone VR Devices (PICO & Meta Quest)

All steps below work on **Linux, Windows, and macOS** to set up Android OpenXR builds locally on a fresh clone.

### Step 5.1 — Install Android Build Toolchain (Once per Machine)
1. **OpenJDK 17:** Install JDK 17 (e.g., Adoptium Temurin 17). Gradle builds for Godot 4.7 require Java 17.
2. **Android SDK & Command-Line Tools:** Install Android SDK (via Android Studio SDK Manager or `cmdline-tools`) with the packages required by `godot/export_presets.cfg` (`min_sdk = 29`, `target_sdk = 36`, `arm64-v8a`):
   - `platform-tools` (`adb`)
   - `platforms;android-36`
   - `build-tools;36.1.0`
   Accept SDK licenses in a terminal:
   ```bash
   sdkmanager --licenses
   ```
3. **Debug Keystore (`debug.keystore`):** Generate a debug keystore if you do not already have `~/.android/debug.keystore` (on Windows `%USERPROFILE%\.android\debug.keystore`):
   ```bash
   keytool -genkeypair -v -storetype PKCS12 -keystore debug.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -storepass android -keypass android -dname "CN=Android Debug,O=Android,C=US"
   ```

### Step 5.2 — Configure Godot Editor for Android Export
1. Open the project in **Godot 4.7.2.stable** (`godot/project.godot`).
2. **Install Export Templates:** `Editor -> Manage Export Templates...` -> download & install **`4.7.2.stable`**.
3. **Set Android Paths:** Open `Editor -> Editor Settings -> Export -> Android`:
   - `Java SDK Path`: root folder of your JDK 17 installation.
   - `Android SDK Path`: root folder of your Android SDK.
   - `Debug Keystore`: path to `debug.keystore` (`Debug Keystore User = androiddebugkey`, `Debug Keystore Pass = android`).
4. **Install Android Build Template (Required for Gradle + OpenXR Vendors v5.2.0):**
   - Click `Project -> Install Android Build Template...` and confirm to populate gitignored `godot/android/build/`.

### Step 5.3 — Prepare VR Headset & Verify ADB Connection
- **PICO 4 / PICO 4 Ultra:**
  1. Put on headset -> `Settings -> General -> About -> Software Version` (tap 7–8 times until Developer Mode unlocks).
  2. Open `Settings -> Developer` and enable **USB Debugging**.
  3. Connect via USB-C data cable and accept **"Allow USB debugging"** (*Always allow from this computer*) inside the headset.
- **Meta Quest 2 / 3 / 3S:**
  1. Enable **Developer Mode** for your headset in the **Meta Horizon** mobile app.
  2. Connect via USB-C data cable and accept **"Allow USB debugging"** (*Always allow from this computer*) inside the headset.
- **Verify ADB (`Linux / macOS / Windows`):**
  ```bash
  adb start-server
  adb devices -l
  ```
  Your headset must show status **`device`** (not `unauthorized`).
  > **Linux USB Tip:** If `adb devices -l` shows `no permissions`, add your user to `plugdev` / install `android-udev` rules (`0x2d40` for PICO, `0x2833` for Meta) and run `adb kill-server && adb start-server`.

### Step 5.4 — Export & Install APK on Headset

#### Method A — Godot Editor Export or One-Click Remote Deploy (Linux, Windows, macOS)
- **One-Click Deploy:** With the headset connected and authorized in `adb devices`, click the **Remote Deploy (Android)** icon in the top-right Godot Editor toolbar and select **`PICO 4 Ultra (Android OpenXR)`** or **`Meta Quest (Android OpenXR)`**.
- **Manual APK Export:** Open `Project -> Export...`, choose:
  - **`PICO 4 Ultra (Android OpenXR)`** (`preset.0` -> `godot/build/ZenoFit-Godot-Pico4Ultra.apk`), or
  - **`Meta Quest (Android OpenXR)`** (`preset.1` -> `godot/build/ZenoFit-Godot-Quest.apk`),
  and click **Export Project**.

#### Method B — CLI Export + Manual ADB Sideload & Launch (Linux, Windows, macOS)
Run from the repository root (`XR-FP/`, substituting your OS Godot binary if not on `PATH`):

1. **Export APK:**
   ```bash
   # PICO 4 / PICO 4 Ultra (preset.0)
   godot --headless --xr-mode off --path godot --export-debug "PICO 4 Ultra (Android OpenXR)" build/ZenoFit-Godot-Pico4Ultra.apk

   # Meta Quest 2 / 3 / 3S (preset.1)
   godot --headless --xr-mode off --path godot --export-debug "Meta Quest (Android OpenXR)" build/ZenoFit-Godot-Quest.apk
   ```
2. **Sideload & Launch via ADB** (add `-s <serial>` if multiple ADB devices are connected):
   ```bash
   adb shell am force-stop com.zenofit.godot.mockup
   adb install -r godot/build/ZenoFit-Godot-Pico4Ultra.apk   # or ZenoFit-Godot-Quest.apk
   adb shell monkey -p com.zenofit.godot.mockup -c android.intent.category.LAUNCHER 1
   ```

#### Method C — Local Maintainer Scripts (Optional, Linux Workstation Only)
If you are on the maintainer Linux setup that already has the gitignored `.android-build-tools/` directory populated (`jdk17/`, `sdk/`, `debug.keystore`), these scripts automate `editor_settings-4.7.tres`, Android Build Template installation, export, `adb install -r`, and launch:
- **PICO 4 / PICO 4 Ultra:** `./.android-build-tools/build_and_install_pico.sh` (exports `godot/build/ZenoFit-Godot-Pico.apk`)
- **Meta Quest 2 / 3 / 3S:** `./.android-build-tools/build_and_install_quest.sh` (exports `godot/build/ZenoFit-Godot-Quest.apk`)

> Fresh Git clones do **not** include `.android-build-tools/`, and those scripts reference hardcoded Linux workstation paths (`/usr/bin/godot`, `/home/ramirez/...`). On any other Linux/Windows/macOS machine, use **Method A** or **Method B**.

### Step 5.5 — Device Logs, Clean Reinstall & Linux Desktop Export
- **View runtime logs from headset:** `adb logcat -s godot`
- **Clean reinstall (clears cached permissions/APK signature mismatch):** `adb uninstall com.zenofit.godot.mockup`
- **Standalone Linux Desktop Binary (`preset.2`):**
  ```bash
  godot --headless --xr-mode off --path godot --export-debug "Linux Desktop Simulator" build/ZenoFit-Godot-Desktop.x86_64
  ```
