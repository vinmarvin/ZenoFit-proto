#!/usr/bin/env bash
# ==============================================================================
# ZenoFit VR — Live USB Screen Cast & Optional MP4 Recording Script
# Works with PICO 4, PICO 4 Ultra, and Meta Quest 2 / 3 / 3S over USB-C (ADB).
# Zero Wi-Fi required (bypasses phone hotspot AP Client Isolation).
# No files or apps are installed or written onto the VR headset.
#
# Usage:
#   ./scripts/cast_vr_screen.sh                 # Live 60 FPS window via ffplay
#   ./scripts/cast_vr_screen.sh record out.mp4  # Live window + save MP4 video
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Locate adb automatically
if command -v adb >/dev/null 2>&1; then
    ADB="adb"
elif [ -x "$REPO_ROOT/.android-build-tools/sdk/platform-tools/adb" ]; then
    ADB="$REPO_ROOT/.android-build-tools/sdk/platform-tools/adb"
elif [ -n "$ANDROID_HOME" ] && [ -x "$ANDROID_HOME/platform-tools/adb" ]; then
    ADB="$ANDROID_HOME/platform-tools/adb"
elif [ -x "$HOME/Android/Sdk/platform-tools/adb" ]; then
    ADB="$HOME/Android/Sdk/platform-tools/adb"
else
    echo "ERROR: 'adb' not found. Install android-tools (e.g., sudo pacman -S android-tools) or set ANDROID_HOME."
    exit 1
fi

if ! command -v ffplay >/dev/null 2>&1; then
    echo "ERROR: 'ffplay' not found. Install ffmpeg (e.g., sudo pacman -S ffmpeg)."
    exit 1
fi

"$ADB" start-server >/dev/null 2>&1 || true
echo "Connected VR devices:"
"$ADB" devices -l

if [ "${1:-}" = "record" ]; then
    OUT_FILE="${2:-zenofit_gameplay_$(date +%Y%m%d_%H%M%S).mp4}"
    echo "Streaming live VR view AND recording to: $OUT_FILE"
    echo "Put on the headset (or cover the proximity sensor between lenses). Press 'q' in the window to stop."
    (
      while "$ADB" get-state >/dev/null 2>&1; do
        "$ADB" exec-out screenrecord --bit-rate=16m --output-format=h264 - 2>/dev/null || break
      done
    ) | tee >(ffmpeg -y -f h264 -i - -c copy "$OUT_FILE" >/dev/null 2>&1) \
      | ffplay -window_title "ZenoFit VR USB Cast [RECORDING -> $OUT_FILE] (Press Q to stop)" \
        -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
    echo "Saved recording to: $OUT_FILE"
else
    echo "Starting live 60 FPS USB Screen Cast..."
    echo "Put on the headset (or cover the proximity sensor between lenses). Press 'q' in the window to quit."
    (
      while "$ADB" get-state >/dev/null 2>&1; do
        "$ADB" exec-out screenrecord --bit-rate=16m --output-format=h264 - 2>/dev/null || break
      done
    ) | ffplay -window_title "ZenoFit VR USB Screen Cast (Press Q to quit)" \
        -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
fi
