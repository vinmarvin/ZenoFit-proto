# ZenoFit (Godot 4.x) — Panduan Build & Pengujian untuk Meta Quest 3 / 3S / 2

Panduan ini menjelaskan langkah-langkah untuk melakukan build, instalasi (`.apk`), dan pengujian **ZenoFit** (`/home/ramirez/XR/GodotMockup/mockup-v-1`) pada **Meta Quest 3**, **Meta Quest 3S**, dan **Meta Quest 2**.

---

## 1. Dukungan Meta Quest yang Sudah Dikonfigurasi di Proyek

Proyek ini telah dikonfigurasi agar siap diekspor ke perangkat Meta Quest:
- **Preset Ekspor (`Preset 1`)**: [`export_presets.cfg`](../../export_presets.cfg) menyediakan preset **`"Meta Quest (Android OpenXR)"`**:
  - `export_path = "build/ZenoFit-Godot-Quest.apk"`
  - `xr_features/xr_mode = 1` (OpenXR)
  - `xr_features/enable_meta_plugin = true` (menggunakan plugin vendor Meta `godotopenxr-meta-*.aar` di dalam `addons/godotopenxrvendors/`)
  - `meta_xr_features/hand_tracking = 1` (mendukung kontroler Quest Touch Plus maupun pelacakan tangan)
  - `architectures/arm64-v8a = true`, `min_sdk = "29"`, `target_sdk = "36"`
- **Peta Aksi Kontroler (`openxr_action_map.tres`)**:
  - Menyertakan profil interaksi `/interaction_profiles/oculus/touch_controller` (**Kontroler Meta Quest Touch / Touch Plus**) dan `/interaction_profiles/ext/hand_interaction_ext`.
- **Ruang Referensi Duduk (`LOCAL`)**:
  - Dikunci ke `XRInterface.XR_REFERENCE_SPACE_TYPE_LOCAL` (`openxr/reference_space=1`) dengan sinkronisasi *refresh rate* otomatis (`72 / 90 / 120 Hz`).

---

## 2. Cara Mengaktifkan Mode Pengembang (*Developer Mode*) di Meta Quest 3

Sebelum menginstal `.apk` melalui kabel USB, aktifkan *Developer Mode* pada headset Meta Quest 3 Anda:

1. **Daftarkan Organisasi Pengembang Meta** (hanya sekali):
   - Buka https://developer.oculus.com/manage/organizations/create/ dan masuk dengan akun Meta yang digunakan pada Quest 3 Anda.
2. **Aktifkan Developer Mode di Aplikasi Ponsel Meta Horizon**:
   - Buka aplikasi **Meta Horizon** di ponsel Anda (pastikan Bluetooth menyala dan berada di dekat Quest 3 yang menyala).
   - Ketuk **Menu (☰) → Perangkat (Devices) → pilih Meta Quest 3 Anda → Pengaturan Headset (Headset Settings) → Mode Pengembang (Developer Mode)**.
   - Geser tombol **Developer Mode** ke posisi **AKTIF (ON)**.
3. **Hubungkan Kabel USB-C & Izinkan USB Debugging**:
   - Hubungkan Meta Quest 3 ke PC menggunakan kabel USB-C.
   - Kenakan headset dan klik **Izinkan (Allow)** pada notifikasi **"Allow USB debugging?"** yang muncul di dalam headset.
   - Pastikan perangkat terdeteksi di PC dengan perintah:
     ```bash
     adb devices -l
     ```

---

## 3. Build & Install APK Mandiri ke Meta Quest 3

### Opsi A — Skrip 1 Perintah (Sudah Terkonfigurasi di Mesin Ini)
Jalankan skrip otomatis berikut di terminal:
```bash
/home/ramirez/XR/.android-build-tools/build_and_install_quest.sh
```
Skrip ini secara otomatis:
1. Mengatur `JAVA_HOME` (OpenJDK 17) dan `ANDROID_HOME` (Android SDK 36).
2. Memastikan template build Android Godot (`android/build`) sudah terpasang.
3. Mengekspor `build/ZenoFit-Godot-Quest.apk` menggunakan preset `"Meta Quest (Android OpenXR)"`.
4. Menginstal dan langsung menjalankan aplikasi di Meta Quest 3 yang terhubung melalui `adb install -r`.

### Opsi B — Perintah Manual via Terminal
```bash
export JAVA_HOME="/home/ramirez/XR/.android-build-tools/jdk17"
export ANDROID_HOME="/home/ramirez/XR/.android-build-tools/sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

# 1. Ekspor Debug APK untuk Meta Quest 3
/usr/bin/godot --headless --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1 \
  --export-debug "Meta Quest (Android OpenXR)" \
  /home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Quest.apk

# 2. Instal ke Meta Quest 3
adb install -r /home/ramirez/XR/GodotMockup/mockup-v-1/build/ZenoFit-Godot-Quest.apk

# 3. Jalankan langsung di headset
adb shell monkey -p com.zenofit.godot.mockup -c android.intent.category.LAUNCHER 1
```

### Opsi C — Membuka Aplikasi dari Menu di Dalam Meta Quest 3
1. Tekan **tombol Meta** pada kontroler Touch Plus kanan untuk membuka menu utama.
2. Buka **Pustaka Aplikasi (Library)**.
3. Pilih filter **Sumber Tidak Dikenal (Unknown Sources)** (atau **Aplikasi → Filter: Sumber tidak dikenal** pada Horizon OS terbaru).
4. Klik **ZenoFit (Godot)**.

---

## 4. Pemetaan Tombol Kontroler Meta Quest 3 Touch Plus

- **Trigger Telunjuk** atau **Tombol A / X**:
  - **Menu Utama**: Mulai **Score Attack**
  - **Kalibrasi**: Konfirmasi langkah kalibrasi saat ini
  - **Layar Jeda / Konfirmasi Kursi Stabil**: Konfirmasi & Lanjutkan (hitung mundur 3 detik)
  - **Layar Hasil (*Results*)**: Mulai sesi baru
- **Tombol B / Y**:
  - Lewati langkah kalibrasi opsional (seperti penandaan rintangan)
- **Tombol Menu Kiri (☰)**:
  - Jeda (*Pause*) atau Lanjutkan sesi aktif
- **Selama Ronde Latihan Aktif 30 Detik (`M01`–`M10`)**:
  - **Tanpa penekanan tombol** — seluruh 10 mekanik melacak posisi 6DoF tangan (`HandTip_L`, `HandTip_R`) dan postur kepala Anda secara langsung. Istirahatkan kedua tangan di pangkuan selama `2.0 detik` kapan saja untuk memicu **Auto-Pause**.
