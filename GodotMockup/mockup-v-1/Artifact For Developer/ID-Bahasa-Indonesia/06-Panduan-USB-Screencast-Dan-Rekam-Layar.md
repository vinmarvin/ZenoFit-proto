# ZenoFit (Godot 4.x) — Panduan Pengembang: Live USB Screencast & Rekam Layar (`PICO 4` / `PICO 4 Ultra` / `Meta Quest`)

Panduan ini menjelaskan cara menampilkan (*screencast* / *mirror*) atau merekam layar gameplay VR secara langsung dari **PICO 4**, **PICO 4 Ultra**, maupun **Meta Quest 2 / 3 / 3S** ke layar laptop/PC menggunakan kabel USB-C standar—**tanpa memerlukan koneksi Wi-Fi** dan **tanpa mengubah pengaturan atau meninggalkan file apa pun di dalam headset**.

---

## 1. Mengapa Menggunakan USB Screencast Dibandingkan Cast Browser / Wi-Fi?

1. **Bebas Masalah Hotspot HP (*AP Client Isolation*)**:
   - Hotspot Wi-Fi ponsel (Android/iOS) dan jaringan Wi-Fi kampus/kantor mengaktifkan fitur **AP Client Isolation** yang memblokir koneksi lokal langsung (`http://<ip-headset>:8080`) antara headset VR dan laptop Anda.
   - USB Screencast mengalirkan video H.264 langsung melalui kabel USB-C menggunakan `adb exec-out screenrecord`, sehingga 100% bebas kendala jaringan.
2. **100% Aman untuk Perangkat Pinjaman**:
   - Menggunakan utilitas bawaan Android (`screenrecord`) melalui pipa memori (`stdout`).
   - **Tidak ada aplikasi tambahan yang diinstal** ke headset, **tidak ada pengaturan sistem yang diubah**, dan **tidak ada file yang disimpan** di memori internal headset.
3. **Kualitas Tinggi 60 FPS & Latensi Sangat Rendah**:
   - Mengalirkan tampilan layar pada `16 Mbps` / `60 FPS` langsung ke jendela `ffplay` (atau `scrcpy`) di laptop Anda.

---

## 2. Prasyarat

1. **Pada Headset VR**:
   - **USB Debugging** sudah aktif (lihat [`03-README-Panduan-Setup-Testing-Dan-Build-PICO4Ultra.md`](./03-README-Panduan-Setup-Testing-Dan-Build-PICO4Ultra.md) untuk PICO atau [`05-Panduan-Build-Dan-Testing-Meta-Quest.md`](./05-Panduan-Build-Dan-Testing-Meta-Quest.md) untuk Meta Quest).
   - Terhubung ke laptop/PC melalui kabel USB-C (dan izin **"Allow USB debugging"** sudah disetujui di dalam headset).
2. **Pada Laptop / PC**:
   - `adb` (paket `android-tools` atau Android SDK `platform-tools`)
   - `ffplay` & `ffmpeg` (`sudo pacman -S ffmpeg` di Arch Linux, atau `sudo apt install ffmpeg` di Ubuntu)

---

## 3. Mulai Cepat: Menggunakan Skrip Screencast Bawaan Proyek

Repositori ini menyertakan skrip siap pakai di [`scripts/cast_vr_screen.sh`](../../scripts/cast_vr_screen.sh) yang secara otomatis mendeteksi lokasi `adb` (baik dari `$PATH` sistem, `$ANDROID_HOME`, maupun `.android-build-tools/`) dan membuka jendela *screencast*.

### Opsi A — Menampilkan Layar VR Langsung (Live 60 FPS)
Jalankan dari folder `/home/ramirez/XR/GodotMockup/mockup-v-1`:
```bash
./scripts/cast_vr_screen.sh
```
- **Penting**: Kenakan headset VR (atau tutup **sensor jarak di antara kedua lensa** dengan jari) agar layar headset menyala dan mulai mengirimkan frame video.
- Tekan tombol **`q`** pada jendela video di laptop kapan saja untuk menutup *screencast*.

### Opsi B — Menampilkan Layar Sekaligus Merekam Video `.mp4` (untuk Demo / Dokumentasi)
Jika Anda ingin menampilkan layar di laptop **sekaligus menyimpannya menjadi file video `.mp4`** di laptop Anda:
```bash
./scripts/cast_vr_screen.sh record demo_gameplay.mp4
```
- Tekan **`q`** pada jendela video saat selesai—file `demo_gameplay.mp4` akan tersimpan di laptop Anda (dan `.gitignore` sudah diatur untuk mengabaikan `*.mp4` agar file video besar tidak ikut ter-push ke Git).

---

## 4. Perintah Manual Satu Baris (Tanpa Skrip)

Anda juga dapat menjalankan perintah ini secara langsung dari terminal mana saja:

```bash
adb exec-out screenrecord --bit-rate=16m --output-format=h264 - | \
  ffplay -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
```

### Menampilkan Satu Mata Saja (Opsional — Tampilan Tunggal untuk Presentasi)
Karena headset VR merender dua lensa kiri-kanan (`4320x2160` pada PICO 4), Anda dapat memotong tampilan hanya pada **mata kiri** (`crop=iw/2:ih:0:0`) agar penonton di layar laptop melihat satu layar normal:

```bash
adb exec-out screenrecord --bit-rate=16m --output-format=h264 - | \
  ffplay -vf "crop=iw/2:ih:0:0,scale=1080:1080" \
  -framerate 60 -probesize 32 -fflags nobuffer -flags low_delay -framedrop -sync video -
```

---

## 5. Cara Menghapus Aplikasi Uji Coba Saat Mengembalikan Headset Pinjaman

Setelah selesai melakukan pengujian pada perangkat PICO 4, PICO 4 Ultra, atau Meta Quest pinjaman, Anda dapat menghapus aplikasi `ZenoFit` hingga bersih seperti semula dengan perintah:
```bash
adb uninstall com.zenofit.godot.mockup
```
