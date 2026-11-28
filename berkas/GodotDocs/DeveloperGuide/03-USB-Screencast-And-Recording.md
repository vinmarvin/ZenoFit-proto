# 03 — USB Screen Cast & Gameplay Recording

> **Script Location:** [`godot/scripts/cast_vr_screen.sh`](../../../godot/scripts/cast_vr_screen.sh)

This guide explains how to mirror and record live headset gameplay over **USB-C (`ADB`)** at up to **60 FPS** (`16 Mbps` H.264) on **Linux, macOS, and Windows** — without Wi-Fi (eliminating mobile hotspot AP Client Isolation issues) and without installing any companion app on the headset. Compatible with **PICO 4 / PICO 4 Ultra** and **Meta Quest 2 / 3 / 3S**.

---

## 1. Prerequisites (Per Operating System)

Before casting or recording, make sure your headset has **Developer Mode + USB Debugging** enabled and shows **`device`** (not `unauthorized`) in `adb devices -l` (see [`02-Setup-Testing-And-Build.md`](./02-Setup-Testing-And-Build.md) §5.3).

### Linux
- **Arch Linux:**
  ```bash
  sudo pacman -S android-tools ffmpeg
  ```
- **Ubuntu / Debian:**
  ```bash
  sudo apt update && sudo apt install -y adb ffmpeg
  ```
- **Fedora:**
  ```bash
  sudo dnf install android-tools ffmpeg
  ```

### macOS (Homebrew)
```bash
brew install android-platform-tools ffmpeg
```

### Windows
- Install **`adb`** (`platform-tools`) and **`ffmpeg`** (`ffplay`), or install **`scrcpy`** (recommended easiest option on Windows, bundles `adb` and handles preview + recording cleanly):
  ```powershell
  winget install Google.PlatformTools
  winget install Gyan.FFmpeg
  winget install Genymobile.scrcpy
  ```

---

## 2. Using the Bundled USB Cast Script (Linux & macOS)

[`godot/scripts/cast_vr_screen.sh`](../../../godot/scripts/cast_vr_screen.sh) automatically:
1. Locates `adb` in order from `PATH`, `.android-build-tools/sdk/platform-tools/adb`, `$ANDROID_HOME/platform-tools/adb`, or `~/Android/Sdk/platform-tools/adb`.
2. Loops `adb exec-out screenrecord --bit-rate=16m --output-format=h264 -` so streaming continues smoothly past Android's default 3-minute `screenrecord` cap.
3. Saves `.mp4` files locally (`*.mp4` is gitignored in [`.gitignore`](../../../.gitignore) so recordings never clutter Git).

If the script is not yet executable, run once:
```bash
chmod +x godot/scripts/cast_vr_screen.sh
```

### Live 60 FPS Preview Window
Run from the repository root (`/home/ramirez/XR-FP` or your clone root):
```bash
./godot/scripts/cast_vr_screen.sh
```

### Live Preview + Simultaneous MP4 Recording
```bash
./godot/scripts/cast_vr_screen.sh record zenofit_demo.mp4
```
If the output filename is omitted after `record`, it saves to `zenofit_gameplay_<YYYYMMDD_HHMMSS>.mp4` in your current working directory.

> **Important:**
> - Put on the headset (or cover the forehead proximity sensor between the lenses) so Android keeps rendering frames to `screenrecord`.
> - Press **`q`** inside the `ffplay` window to stop streaming cleanly and finalize the MP4 container header.

---

## 3. Cross-Platform Alternatives & Audio Recording

### Option A — `scrcpy` (Recommended on Windows; Works on Linux & macOS)
`scrcpy` mirrors over USB-C natively without Bash process substitution (`tee >(...)`) issues on Windows:
```bash
# Live preview window
scrcpy --video-bit-rate=16M --max-fps=60

# Live preview + MP4 recording
scrcpy --record=zenofit_demo.mp4 --video-bit-rate=16M --max-fps=60
```

### Option B — Windows `cmd.exe` / On-Device `adb screenrecord`
- **Live preview only (`cmd.exe` — avoid PowerShell for raw binary piping):**
  ```cmd
  adb exec-out screenrecord --bit-rate=16m --output-format=h264 - | ffplay -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
  ```
- **Record to headset storage & pull to PC (PowerShell / cmd / bash):**
  ```powershell
  adb shell screenrecord --bit-rate 16000000 /sdcard/zenofit_demo.mp4
  # Press Ctrl+C when finished, wait 2 seconds for file finalization, then pull:
  adb pull /sdcard/zenofit_demo.mp4 .
  adb shell rm /sdcard/zenofit_demo.mp4
  ```

### Option C — Built-In Headset Recording (When You Need Game Audio / Voiceover)
> **Note:** `adb screenrecord` captures **video only (no audio)**. Use the headset's built-in recorder whenever you need procedural dojo SFX or voiceover in demo videos.

- **PICO 4 / PICO 4 Ultra:** Start **Screen Record** from the PICO Quick Settings menu (toggle mic/system audio if needed), stop recording, then pull from the headset via USB:
  ```bash
  adb shell ls -lt /sdcard/DCIM/ScreenRecorder/
  adb pull "/sdcard/DCIM/ScreenRecorder/<filename>.mp4" .
  ```
- **Meta Quest 2 / 3 / 3S:** Open **Meta Menu -> Camera -> Record Video** (supports mic/audio), stop recording, then pull from the headset via USB:
  ```bash
  adb shell ls -lt /sdcard/Oculus/VideoShots/
  adb pull "/sdcard/Oculus/VideoShots/<filename>.mp4" .
  ```

### Optional Post-Processing — Crop Side-by-Side Stereo Video to Single Eye
If `adb screenrecord` outputs side-by-side dual-eye frames, crop cleanly to the left eye (`x=0`) or right eye (`x=iw/2`) with `ffmpeg`:
```bash
ffmpeg -i zenofit_demo.mp4 -vf "crop=iw/2:ih:0:0" -c:v libx264 -crf 18 zenofit_left_eye.mp4
```

---

## 4. Troubleshooting

- **`unauthorized` device in `adb devices -l`:** Put on the headset and accept **"Allow USB debugging"** (*Always allow from this computer*).
- **Multiple ADB devices connected:** Export `ANDROID_SERIAL=<serial>` before running `cast_vr_screen.sh` (or pass `adb -s <serial>` / `scrcpy -s <serial>`).
- **Black screen or frozen frame during cast:** Headset entered sleep mode while resting on a desk; wear the headset (or cover the proximity sensor) and ensure ZenoFit is active in the foreground.
- **`ERROR: 'adb' not found` or `'ffplay' not found`:** Install `android-tools`/`platform-tools` and `ffmpeg` per §1 and ensure both binaries are on `PATH`.
- **MP4 fails to open after recording:** Always quit `ffplay` by pressing **`q`** inside the video window (avoid force-killing the terminal) so `ffmpeg` writes the closing MP4 `moov` metadata.
- **Windows Git Bash `tee >(...)` error:** Prefer **`scrcpy`** (§3 Option A) or on-device `screenrecord` + `adb pull` (§3 Option B) on Windows.
