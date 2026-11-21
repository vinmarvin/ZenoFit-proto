# ZenoFit (Godot 4.x) — Developer Guide: Live USB Screen Casting & Recording (`PICO 4` / `PICO 4 Ultra` / `Meta Quest`)

This guide explains how any developer or tester can mirror (cast) or record live VR gameplay from a **PICO 4**, **PICO 4 Ultra**, or **Meta Quest 2 / 3 / 3S** onto a laptop/PC over a standard USB-C cable—with **zero Wi-Fi required** and **zero modifications to the headset**.

---

## 1. Why Use USB Screen Casting Instead of Wi-Fi / Browser Cast?

1. **Works on Mobile Hotspots & Campus/Office Wi-Fi**:
   - Phone Wi-Fi hotspots (Android/iOS) and university/office networks enable **AP Client Isolation**, which blocks direct peer-to-peer HTTP/WebRTC connections (`http://<headset-ip>:8080`) between the headset and your laptop.
   - USB Screen Casting streams raw H.264 video directly over the USB-C cable via `adb exec-out screenrecord`, bypassing Wi-Fi completely.
2. **100% Safe for Borrowed / Shared Devices**:
   - Uses Android's built-in `screenrecord` utility (`stdout` pipe).
   - **Nothing is installed** on the headset, **no settings are altered**, and **zero files are written** to the headset's internal storage.
3. **High Resolution & 60 FPS Low-Latency**:
   - Streams full stereo or single-eye buffer at `16 Mbps` / `60 FPS` straight into `ffplay` (or `scrcpy`).

---

## 2. Prerequisites

1. **On the VR Headset**:
   - **USB Debugging** enabled (see [`03-README-Setup-Testing-And-Build.md`](./03-README-Setup-Testing-And-Build.md) for PICO or [`05-Guide-Build-And-Test-Meta-Quest.md`](./05-Guide-Build-And-Test-Meta-Quest.md) for Meta Quest).
   - Connected to your PC via a USB-C cable (and **"Allow USB debugging"** accepted inside the headset).
2. **On Your Linux / macOS / Windows PC**:
   - `adb` (`android-tools` package or Android SDK `platform-tools`)
   - `ffplay` & `ffmpeg` (`sudo pacman -S ffmpeg` on Arch Linux, `sudo apt install ffmpeg` on Ubuntu)

---

## 3. Quick Start: Run the Included Screencast Script

The repository includes a ready-to-use script at [`scripts/cast_vr_screen.sh`](../scripts/cast_vr_screen.sh) that automatically finds `adb` (either from your system `$PATH`, `$ANDROID_HOME`, or `.android-build-tools/`) and opens the live cast window.

### Option A — Live 60 FPS Screen Cast Window
From `/home/ramirez/XR/GodotMockup/mockup-v-1`:
```bash
./scripts/cast_vr_screen.sh
```
- **Important**: Put on the headset (or place a finger over the **proximity sensor between the lenses**) so the headset display wakes up and begins sending video frames.
- Press **`q`** inside the `ffplay` window anytime to close the cast.

### Option B — Live Screen Cast + Save `.mp4` Video for Tutorials / Demos
To watch the live cast on your laptop **and simultaneously save an `.mp4` video file** on your PC:
```bash
./scripts/cast_vr_screen.sh record demo_gameplay.mp4
```
- Press **`q`** in the video window when finished—`demo_gameplay.mp4` will be saved on your PC (and `.gitignore` automatically ignores `*.mp4` files so you won't accidentally push large video recordings to Git).

---

## 4. One-Line Manual Command (Without the Script)

If you ever want to run the cast manually from any terminal:

```bash
adb exec-out screenrecord --bit-rate=16m --output-format=h264 - | \
  ffplay -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
```

### Cropping to a Single Eye (Optional — Clean 16:9 View for Presentations)
Because VR headsets render a side-by-side stereo image (`4320x2160` on PICO 4), you can crop to the **left eye only** (`iw/2:ih:0:0`) so viewers see a normal single-screen 2D view:

```bash
adb exec-out screenrecord --bit-rate=16m --output-format=h264 - | \
  ffplay -vf "crop=iw/2:ih:0:0,scale=1080:1080" \
  -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
```

---

## 5. Alternative: Using `scrcpy` (If Installed)

If you have [`scrcpy`](https://github.com/Genymobile/scrcpy) installed (`sudo pacman -S scrcpy` or `sudo apt install scrcpy`):
- **Full Stereo Mirror**:
  ```bash
  scrcpy --no-control
  ```
- **Single-Eye Cropped Mirror (for PICO 4 `2160x2160` per eye)**:
  ```bash
  scrcpy --no-control --crop=2160:2160:0:0
  ```

---

## 6. Cleanly Removing the Test App from a Borrowed Headset

When you finish testing on a borrowed PICO 4, PICO 4 Ultra, or Meta Quest headset and want to remove the `ZenoFit` APK completely:
```bash
adb uninstall com.zenofit.godot.mockup
```
