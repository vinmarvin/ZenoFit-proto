# 03 — USB Screen Cast & Gameplay Recording

> **Script Location:** [`godot/scripts/cast_vr_screen.sh`](../../../godot/scripts/cast_vr_screen.sh)

This script mirrors and records live headset gameplay over **USB-C (`ADB`)** at up to **60 FPS** using **`ffplay`**, eliminating Wi-Fi AP Client Isolation issues on mobile hotspots without installing anything on the headset.

---

## 1. Prerequisites

- **USB-C Cable** connected to PICO 4 / PICO 4 Ultra or Meta Quest 2 / 3 / 3S with **Developer Mode + USB Debugging** enabled.
- **`adb`**: Auto-detected in order from `PATH`, `.android-build-tools/sdk/platform-tools/adb`, `$ANDROID_HOME`, or `~/Android/Sdk`.
- **`ffmpeg` / `ffplay`**: Required for low-latency H.264 playback and MP4 saving (`sudo pacman -S ffmpeg` or `sudo apt install ffmpeg`).

---

## 2. Usage

### Live 60 FPS Preview Window
From the repository root (`/home/ramirez/XR-FP`):

```bash
./godot/scripts/cast_vr_screen.sh
```

### Live Preview + Simultaneous MP4 Recording
```bash
./godot/scripts/cast_vr_screen.sh record zenofit_demo.mp4
```
If the filename argument is omitted after `record`, it saves to `zenofit_gameplay_<YYYYMMDD_HHMMSS>.mp4` in the current working directory.

> **Important:** Put on the headset (or cover the forehead proximity sensor between the lenses) so Android keeps rendering frames to `screenrecord`. Press **`q`** inside the `ffplay` window to quit streaming and finalize the MP4 file cleanly.

---

## 3. Troubleshooting

- **`unauthorized` device in `adb devices -l`:** Put on the headset and accept **"Allow USB debugging"** (*Always allow from this computer*).
- **Black screen during cast:** Headset entered sleep mode while sitting on a desk; wear the headset or trigger the proximity sensor, then relaunch the app.
