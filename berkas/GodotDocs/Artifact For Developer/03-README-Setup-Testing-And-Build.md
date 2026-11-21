# ZenoFit (Godot 4.x) — Setup, PICO 4 Ultra Testing, & Build Guide

This README walks you through running, testing on **PICO 4 Ultra** (both via live PCVR streaming and standalone Android APK builds), and running the Desktop Simulator for **ZenoFit** (`/home/ramirez/XR/GodotMockup/mockup-v-1`).

---

## 1. Quick Start: Run in Desktop Simulator (No Headset Connected)

You can test the entire game loop, all 7 calibration steps, the interactive `Floating Mascots.glb` companion, and all 10 exercise mechanics (`M01`–`M10`) directly on your Linux/Windows/macOS desktop.

### Option A — Launch from Terminal
```bash
/usr/bin/godot --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1
```

### Option B — Launch from Godot Editor
1. Open Godot 4.x (`/usr/bin/godot`).
2. Import or open `/home/ramirez/XR/GodotMockup/mockup-v-1/project.godot`.
3. Press **F5** (Play). If no OpenXR runtime is active, the game automatically boots into **Desktop Simulator Mode**.

### Desktop Simulator Controls (Keyboard + Mouse + Bottom HUD)
- **Bottom 2D Simulator Bar**: Click any button along the bottom of the window to navigate menus (`Accept Disclaimer`, `Score Attack`, `Practice Mode`, `Calibrate`, `Difficulty`, `No-Trunk Mode`, etc.).
- **Keyboard Shortcuts during Calibration & Rounds**:
  - `Space`: Confirm current prompt / advance step / start round
  - `Tab`: Cycle selected mechanic (`M01`..`M10`) in Practice Mode
  - **Hold `Q` + Move Mouse**: Move **Left Hand** (`HandTip_L`) in 3D space (`Scroll Wheel` pushes forward/backward)
  - **Hold `E` + Move Mouse**: Move **Right Hand** (`HandTip_R`) in 3D space (`Scroll Wheel` pushes forward/backward)
  - `L`: Perform a fast **Left Hand Punch** (`M01` / target tap)
  - `R`: Perform a fast **Right Hand Punch** (`M01` / target tap)
  - `P`: Perform a **Synchronized Two-Hand Force Push** (`M06`)
  - `T`: Hold **Bilateral T-Pose Wings** (`M03`)
  - `O`: Hold **Lap Rest Pose** (`y <= y_lap` — triggers Auto-Pause after `2.5 s`)
  - `J` / `U`: Rotate **Head Yaw Left / Right** (`M08` Recon Scanner)
  - `Z` / `C`: **Lateral Trunk Lean Left / Right** (`M10` Laser Evader)
  - `K`: **Poke / Touch ZenoBot Mascot Coach** (triggers wave, bounce, speech bubble, and haptic event)
  - `M`: Cycle Mascot Coach exercise demonstration (`M01` → `M10`)
  - `N`: Instantly auto-complete current calibration with comfortable default values
  - `Esc`: Pause / Resume active round

---

## 2. PICO 4 Ultra — Pre-Configured OpenXR Bindings

[`openxr_action_map.tres`](../openxr_action_map.tres) and [`project.godot`](../project.godot) are pre-configured for the **PICO 4 Ultra**:
- **Ringless PICO 4 Ultra Controller Profile**: `/interaction_profiles/bytedance/pico4s_controller` (`OpenXRInteractionProfile_p4ultra`)
- **PICO 4 Standard Controller Profile**: `/interaction_profiles/bytedance/pico4_controller` (`OpenXRInteractionProfile_d3nfp`)
- **Hand Interaction Profile (Controller-Free Hand Tracking)**: `/interaction_profiles/ext/hand_interaction_ext` (`openxr/extensions/hand_tracking=true`, `openxr/extensions/hand_interaction_profile=true`)
- **Seated Reference Space**: `XRInterface.XR_REFERENCE_SPACE_TYPE_LOCAL` (`openxr/reference_space=1`) and `90 Hz` display sync on PICO 4 Ultra.

---

## 3. Live Dev Testing on PICO 4 Ultra via PCVR Streaming

If you want instant iteration from your PC without building an APK on every change:

### Option A — On Linux (Arch Linux / Ubuntu) using WiVRn or ALVR
1. Install **WiVRn** (`yay -S wivrn-server wivrn-dashboard`) or **ALVR** (`yay -S alvr`).
2. Sideload the **WiVRn** (or **ALVR**) client APK onto your PICO 4 Ultra (available on GitHub Releases for PICO).
3. Connect your PICO 4 Ultra via USB-C or 5 GHz / Wi-Fi 6/7 LAN and connect to the server on your PC.
4. Ensure WiVRn/Monado or SteamVR is set as your active OpenXR runtime (`~/.config/openxr/1/active_runtime.json`).
5. Run ZenoFit with XR enabled:
   ```bash
   /usr/bin/godot --xr-mode on --path /home/ramirez/XR/GodotMockup/mockup-v-1
   ```

### Option B — On Windows using PICO Connect + SteamVR
1. Install **PICO Connect** on your PC and open the **PICO Connect** app on your PICO 4 Ultra.
2. Connect via USB-C or Wi-Fi and launch **SteamVR** (ensure SteamVR is set as the active OpenXR runtime in SteamVR Settings → OpenXR).
3. Press **F5** in the Godot Editor (or run with `--xr-mode on`) to stream directly into the PICO 4 Ultra headset.

---

## 4. Building & Deploying Standalone APK to PICO 4 Ultra

[`export_presets.cfg`](../export_presets.cfg) includes **Preset 0: `"PICO 4 Ultra (Android OpenXR)"`** (`build/ZenoFit-Godot-Pico4Ultra.apk`).

### Step 4.1 — Enable Developer Mode & USB Debugging on PICO 4 Ultra
1. Put on your **PICO 4 Ultra** and open **Settings → General → About**.
2. Scroll down to **Software Version** and click it **8 times** rapidly until the **"Developer"** menu appears in the left sidebar under Settings.
3. Click **Settings → Developer** and enable **USB Debugging**.
4. Connect your PICO 4 Ultra to your PC via USB-C and verify ADB detects it:
   ```bash
   adb devices
   ```
   *(If prompted inside the headset, click **Allow USB Debugging**).*

### Step 4.2 — Install Godot Export Templates & OpenXR Vendors Plugin
1. **Godot Export Templates**:
   - In the Godot Editor, open **Editor → Manage Export Templates** and click **Download and Install**.
2. **Godot OpenXR Vendors Plugin v4 (Required for PICO OS 5.x OpenXR Loader)**:
   - PICO 4 Ultra (PICO OS 5.11+) uses the standard Khronos OpenXR loader packaged in the **Godot OpenXR Vendors plugin**.
   - In Godot Editor, click the **AssetLib** tab at the top, search for **`Godot OpenXR Vendors plugin v4`**, download/install it into `addons/godotopenxrvendors/`, and enable it under **Project → Project Settings → Plugins**.
   - In **Project → Export → PICO 4 Ultra (Android OpenXR)**, confirm **Xr Features → Xr Mode** is `OpenXR` and **Khronos OpenXR Loader → Enabled** is checked (`khronos_openxr_loader/enabled=true` is already set in `export_presets.cfg`).
3. **Android SDK & JDK 17**:
   - Ensure **OpenJDK 17** and **Android SDK** (`platform-tools`, `build-tools;34.0.0`, `platforms;android-34`, `ndk;25.2.9519653`) are configured under **Editor → Editor Settings → Export → Android**.

### Step 4.3 — Export & Sideload APK to PICO 4 Ultra

#### One-Command Build, Install, & Launch Script (Pre-Configured on This Machine)
All portable Android build tools (`OpenJDK 17`, `Android SDK 36`, `adb`, `debug.keystore`, Godot 4.7.2 Android export templates, and `godotopenxrvendors` v5.2.0) are already installed locally in `/home/ramirez/XR/.android-build-tools/`. Run:
```bash
/home/ramirez/XR/.android-build-tools/build_and_install_pico4ultra.sh
```

#### Manual Command-Line Build & ADB Install
```bash
mkdir -p /home/ramirez/XR/GodotMockup/mockup-v-1/build

# Export Debug APK for PICO 4 Ultra
/usr/bin/godot --headless --path /home/ramirez/XR/GodotMockup/mockup-v-1 \
  --export-debug "PICO 4 Ultra (Android OpenXR)" \
  /home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Pico4Ultra.apk

# Install onto connected PICO 4 Ultra via ADB
adb install -r /home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Pico4Ultra.apk

# Launch on PICO 4 Ultra (or open from App Library -> Unknown Sources) and stream logs
adb logcat -c
adb shell am start -n com.zenofit.godot.mockup/com.godot.game.GodotApp
adb logcat -s godot:V
```

#### Option 2: Godot Editor One-Click Deploy
1. Connect your PICO 4 Ultra via USB-C.
2. In the top-right corner of the Godot Editor, click the **Remote Deploy** icon and select **PICO 4 Ultra (Android OpenXR)**.
3. Or on the headset itself, open **App Library → Unknown Sources** and click **ZenoFit (Godot)**.

---

## 5. Running Automated Acceptance Tests (`AT-01`..`AT-28`)

Run the headless verification suite from terminal:
```bash
/usr/bin/godot --headless --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1 -s res://tests/run_acceptance_tests.gd
```
*(Verifies all `68/68` assertions across `SpecSpace`, `BodyFrame`, `AT-01`..`AT-28`, and `FloatingMascotCoach`)*
