# ZenoFit (Godot 4.x) — Panduan Setup, Testing di PICO 4 Ultra, & Build

README ini memandu Anda menjalankan, menguji pada **PICO 4 Ultra** (baik melalui instalasi `.apk` Android mandiri maupun *streaming* PCVR langsung), serta menjalankan Simulator Desktop untuk **ZenoFit** (`/home/ramirez/XR/GodotMockup/mockup-v-1`).

---

## 1. Mulai Cepat: Menjalankan Simulator Desktop (Tanpa Headset VR)

Anda dapat menguji seluruh alur permainan, langkah kalibrasi, maskot interaktif `Floating Mascots.glb`, dan ke-10 mekanik latihan (`M01`–`M10`) langsung di PC Linux/Windows/macOS Anda.

### Jalankan dari Terminal
```bash
/usr/bin/godot --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1
```

### Kontrol Simulator Desktop (Keyboard + Mouse + Bilah Tombol Bawah)
- **Bilah Tombol 2D di Bagian Bawah Layar**: Klik tombol apa saja di bagian bawah jendela untuk menavigasi menu (`Score Attack`, `Practice Mode`, `Calibrate`, `Preset`, `No-Trunk Mode`, `Auto-Hit`, `Poke Mascot`, dll.).
- **Pintasan Keyboard**:
  - `Space`: Konfirmasi langkah kalibrasi saat ini / mulai sesi / lanjutkan ronde
  - `Tab`: Simulasikan aksi sukses otomatis (*Auto-Action*) pada ronde aktif
  - **Tahan `Q` + Gerakkan Mouse**: Gerakkan **Tangan Kiri** di ruang 3D (`Scroll Wheel` untuk maju/mundur)
  - **Tahan `E` + Gerakkan Mouse**: Gerakkan **Tangan Kanan** di ruang 3D (`Scroll Wheel` untuk maju/mundur)
  - `K`: Lewati langkah kalibrasi opsional / tolak kursi stabil (substitusi Level A)
  - `O`: Tandai titik rintangan kursi/meja saat kalibrasi
  - `C`: Buka ulang Kalibrasi dari Menu Utama
  - `L`: Pindahkan kedua tangan ke pangkuan (`LapPoint`) untuk menguji **Auto-Pause 2.0 detik**
  - `R`: Simulasikan event *Recenter* headset
  - `M`: Colek / sentuh maskot pelatih **ZenoBot**
  - `N`: Selesaikan timer ronde aktif dengan cepat (untuk pengujian cepat)
  - `Esc`: Jeda (*Pause*) / Kembali ke Menu Utama

---

## 2. Build & Install APK Mandiri ke PICO 4 Ultra

### Langkah 2.1 — Aktifkan Mode Pengembang (*Developer Mode*) & USB Debugging di PICO 4 Ultra
1. Kenakan headset **PICO 4 Ultra** dan buka **Settings (Pengaturan) → General (Umum) → About (Tentang)**.
2. Gulir ke bawah ke **Software Version (Versi Perangkat Lunak)** lalu **klik 8 kali berturut-turut** hingga menu **Developer** muncul di bilah samping kiri.
3. Buka **Settings → Developer** dan aktifkan **USB Debugging**.
4. Hubungkan PICO 4 Ultra ke PC menggunakan kabel USB-C dan klik **Allow (Izinkan)** pada jendela *Allow USB debugging?* di dalam headset.

### Langkah 2.2 — Build, Install, & Jalankan dalam 1 Perintah
Seluruh perangkat bantu build Android (`OpenJDK 17`, `Android SDK 36`, `adb`, `debug.keystore`, template ekspor Android Godot 4.7.2, dan plugin `godotopenxrvendors` v5.2.0) telah dikonfigurasi di `/home/ramirez/XR/.android-build-tools/`. Cukup jalankan:

```bash
/home/ramirez/XR/.android-build-tools/build_and_install_pico4ultra.sh
```

Skrip ini akan mengekspor `build/ZenoFit-Godot-Pico4Ultra.apk`, menginstalnya ke PICO 4 Ultra melalui `adb install -r`, dan langsung membuka aplikasi di headset Anda (juga tersedia di **App Library → Unknown Sources → ZenoFit (Godot)**).

---

## 3. Kontroler PICO 4 Ultra di Dalam VR

- **Tombol Trigger Telunjuk** atau **Tombol A / X**:
  - **Menu Utama**: Mulai **Score Attack**
  - **Kalibrasi**: Konfirmasi langkah kalibrasi saat ini
  - **Layar Jeda / Konfirmasi Kursi Stabil**: Konfirmasi & Lanjutkan
  - **Layar Hasil (*Results*)**: Mulai sesi baru
- **Tombol B / Y**:
  - Lewati langkah kalibrasi opsional
- **Tombol Menu Kiri**:
  - Jeda (*Pause*) atau Lanjutkan ronde aktif
- **Selama Ronde Latihan Aktif 30 Detik (`M01`–`M10`)**:
  - **Tidak perlu menekan tombol apa pun!** Cukup gerakkan tangan/lengan dan postur kepala Anda di dalam zona nyaman yang telah dikalibrasi (letakkan kedua tangan di pangkuan selama `2.0 detik` kapan saja untuk memicu **Auto-Pause**).

---

## 4. Menjalankan Suite Pengujian Penerimaan Otomatis (`AT-01`..`AT-28`)

Untuk memverifikasi seluruh 68 pengujian matematis dan fungsional secara *headless*:
```bash
/usr/bin/godot --headless --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1 -s res://tests/run_acceptance_tests.gd
```
