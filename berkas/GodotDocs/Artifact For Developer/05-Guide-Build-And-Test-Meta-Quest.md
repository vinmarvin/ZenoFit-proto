# ZenoFit (Godot 4.x) — Meta Quest 3 / 3S / 2 Build & Testing Guide

This guide covers building, deploying, and testing **ZenoFit** (`/home/ramirez/XR/GodotMockup/mockup-v-1`) on **Meta Quest 3**, **Meta Quest 3S**, and **Meta Quest 2** (both as a standalone Android `.apk` and via PCVR streaming).

---

## 1. Pre-Configured Meta Quest Support in the Project

The project is pre-configured for Meta Quest hardware out-of-the-box:
- **Export Preset (`Preset 1`)**: [`export_presets.cfg`](../export_presets.cfg) defines `"Meta Quest (Android OpenXR)"`:
  - `export_path = "build/ZenoFit-Godot-Quest.apk"`
  - `xr_features/xr_mode = 1` (OpenXR)
  - `xr_features/enable_meta_plugin = true` (uses `addons/godotopenxrvendors/.bin/android/*/godotopenxr-meta-*.aar`)
  - `meta_xr_features/hand_tracking = 1` (supports both Quest Touch Plus controllers and controller-free hand tracking)
  - `architectures/arm64-v8a = true`, `min_sdk = "29"`, `target_sdk = "36"`
- **Controller & Hand Action Map**: [`openxr_action_map.tres`](../openxr_action_map.tres) includes:
  - `/interaction_profiles/oculus/touch_controller` (**Meta Quest Touch / Touch Plus Controllers**)
  - `/interaction_profiles/ext/hand_interaction_ext` (**OpenXR Hand Tracking**)
- **Seated Reference Space**: Locked to `XRInterface.XR_REFERENCE_SPACE_TYPE_LOCAL` (`openxr/reference_space=1`) with dynamic refresh rate matching (`72 / 90 / 120 Hz`).

---

## 2. Step-by-Step: Enable Developer Mode on Meta Quest 3 / 3S / 2

Before sideloading an `.apk` via USB, enable Developer Mode on your Quest headset:

1. **Register a Meta Developer Organization** (one-time setup):
   - Go to https://developer.oculus.com/manage/organizations/create/ and sign in with the Meta account logged into your Quest 3.
   - Complete the organization name prompt.
2. **Turn on Developer Mode in the Meta Horizon Phone App**:
   - Open the **Meta Horizon** app on your phone (with Bluetooth enabled near your powered-on Quest 3).
   - Tap **Menu (☰) → Devices → select your Meta Quest 3 → Headset Settings → Developer Mode**.
   - Toggle **Developer Mode ON**.
3. **Connect via USB-C & Authorize ADB**:
   - Plug your Meta Quest 3 into your PC with a USB-C cable.
   - Put on the headset and click **Allow** on the **"Allow USB debugging?"** notification inside the headset (also tap the USB notification if prompted to enable file/debug connection).
   - Verify on your PC:
     ```bash
     adb devices -l
     ```
     You should see your Quest device listed as `device` (e.g., `model:Quest_3`).

---

## 3. Building & Installing the Standalone APK on Meta Quest 3

### Option A — One-Command Build & Install Script (Configured on This Machine)
Run the pre-configured script in `/home/ramirez/XR/.android-build-tools/`:
```bash
/home/ramirez/XR/.android-build-tools/build_and_install_quest.sh
```
This script automatically:
1. Configures Java 17 (`JAVA_HOME`) and Android SDK 36 (`ANDROID_HOME`).
2. Installs the Godot Android build template into `android/build` if not yet present.
3. Exports `/home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Quest.apk` using the `"Meta Quest (Android OpenXR)"` preset.
4. Installs and launches the app on your connected Meta Quest 3 via `adb install -r`.

### Option B — Manual Command-Line Export & Sideload
```bash
export JAVA_HOME="/home/ramirez/XR/.android-build-tools/jdk17"
export ANDROID_HOME="/home/ramirez/XR/.android-build-tools/sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

# 1. Export Debug APK for Meta Quest 3
/usr/bin/godot --headless --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1 \
  --export-debug "Meta Quest (Android OpenXR)" \
  /home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Quest.apk

# 2. Sideload onto Meta Quest 3
adb install -r /home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Quest.apk

# 3. Launch directly on headset (or open from Library -> Applications -> Unknown Sources)
adb shell monkey -p com.zenofit.godot.mockup -c android.intent.category.LAUNCHER 1
```

### Option C — Exporting on a New Machine via Godot Editor GUI
If you clone this repository onto another computer:
1. Install **OpenJDK 17** and **Android SDK** (`platform-tools`, `build-tools;36.1.0`, `platforms;android-36`).
2. In Godot 4.7 Editor:
   - Open **Editor → Manage Export Templates** and download the `4.7.2.stable` templates.
   - Open **Project → Install Android Build Template...** and click **Install**.
   - Open **Editor → Editor Settings → Export → Android** and set your `Java SDK Path`, `Android SDK Path`, and `Debug Keystore`.
3. Open **Project → Export...**, select **`Meta Quest (Android OpenXR)`**, and click **Export Project...** (or click the **Remote Deploy** button in the top-right corner of the editor while your Quest 3 is plugged in).

---

## 4. Where to Launch ZenoFit Inside Meta Quest 3

1. Press the **Meta button** on your right Touch Plus controller to open the universal menu.
2. Open **Library** (app grid icon).
3. On the top-left filter dropdown (or left sidebar), select **Unknown Sources** (or **Applications → Filter: Unknown sources** on Horizon OS v69+).
4. Click **ZenoFit (Godot)**.

---

## 5. Meta Quest 3 Touch Plus Controller Mapping

- **Index Trigger** or **A / X Button**:
  - **Main Menu**: Start **Score Attack**
  - **Calibration**: Confirm current step (Neutral Seat → Left Reach → Right Reach → Overhead → Lap Point → Obstacles)
  - **Pause / Stable Chair Prompt**: Confirm & Resume (3-second countdown)
  - **Results Screen**: Start a new session
- **B / Y Button**:
  - Skip optional calibration steps (e.g., Obstacle Marking)
- **Left Menu Button (☰)**:
  - Pause / Resume active session
- **During Active 30s Rounds (`M01`–`M10`)**:
  - **No button presses required** — all 10 mechanics track your 6DoF hand poses (`HandTip_L`, `HandTip_R`) and head posture (`XRCamera3D`). Rest both hands in your lap for `2.0 s` anytime to trigger **Auto-Pause**.

---

## 6. Live PCVR Streaming to Meta Quest 3 (Optional)

- **On Linux (Arch / Ubuntu)**:
  - Install **WiVRn** (`yay -S wivrn-server wivrn-dashboard`) or **ALVR**, install the WiVRn/ALVR client from the Meta Horizon Store or SideQuest on your Quest 3, connect, and run:
    ```bash
    /usr/bin/godot --xr-mode on --path /home/ramirez/XR/GodotMockup/mockup-v-1
    ```
- **On Windows**:
  - Connect via **Meta Quest Link** / **Air Link** (with Meta Quest Link set as active OpenXR runtime) or **SteamVR**, then press **F5** in Godot.
