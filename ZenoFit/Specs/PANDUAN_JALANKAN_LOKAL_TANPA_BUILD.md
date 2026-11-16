# Panduan Menjalankan & Menguji ZenoFit Secara Lokal (Tanpa Build APK Terlebih Dahulu)

Dokumen ini ditujukan bagi pengembang atau penguji di Indonesia yang ingin **menjalankan, mencoba seluruh fitur, dan mengembangkan proyek ZenoFit langsung di dalam Unity Editor (Play Mode)** tanpa harus melakukan *Build & Run* file `.apk` ke perangkat VR terlebih dahulu.

---

## Daftar Isi
1. [Persiapan Awal Satu Kali di Unity Editor](#1-persiapan-awal-satu-kali-di-unity-editor)
2. [Cara 1: Menjalankan Tanpa Headset VR (Mouse & Keyboard di PC/Laptop)](#2-cara-1-menjalankan-tanpa-headset-vr-mouse--keyboard-di-pclaptop)
3. [Cara 2: Menjalankan Langsung di Headset Meta Quest Tanpa Build APK (Quest Link / Air Link)](#3-cara-2-menjalankan-langsung-di-headset-meta-quest-tanpa-build-apk-quest-link--air-link)
4. [Cara 3: Menjalankan Pengujian Otomatis (Unit Tests AT-01 s/d AT-16)](#4-cara-3-menjalankan-pengujian-otomatis-unit-tests-at-01-sd-at-16)
5. [Lokasi File Data Lokal (JSON Persistence)](#5-lokasi-file-data-lokal-json-persistence)
6. [Pemecahan Masalah Umum (Troubleshooting)](#6-pemecahan-masalah-umum-troubleshooting)

---

## 1. Persiapan Awal Satu Kali di Unity Editor

Saat pertama kali membuka proyek di **Unity 6 (`6000.0.75f1`)**, jalankan menu otomatis berikut dari bilah menu paling atas di Unity Editor:

1. **Perbarui Paket XR (Opsional tetapi Disarankan):**
   - Klik menu **`ZenoFit > 5. Update Packages (Add Meta OpenXR + ARFoundation + XRI, Remove PICO)`**.
   - Tunggu hingga Unity selesai mengunduh/menyesuaikan paket dan melakukan *domain reload*.
2. **Konfigurasi Otomatis Scene, Prefab, dan Aset VR:**
   - Klik menu **`ZenoFit > 1. Run Full VR Project Setup (Quest OpenXR + Scenes + Assets)`**.
   - Menu ini secara otomatis akan:
     - Membuat semua file konfigurasi (`ScriptableObject`) di `Assets/_Project/Resources/Configs/` dan `Assets/_Project/Settings/Presets/`.
     - Membuat prefab `TargetSphere.prefab` di `Assets/_Project/Prefabs/`.
     - Membuat ke-6 scene (`00_Boot` sampai `05_Results`) di `Assets/_Project/Scenes/`.
     - Membuka scene utama **`Assets/_Project/Scenes/00_Boot.unity`** yang sudah memiliki `XR Origin (Seated VR)` dan `ZenoFitSystems`.

> **Penting:** Selalu mulai **Play Mode** dari scene **`00_Boot.unity`** (`Assets/_Project/Scenes/00_Boot.unity`), karena seluruh sistem utama (`GameFlow`, `ZenoFitWorldUI`, `SafetyCoordinator`, `TargetSpawner`) berada di dalam scene tersebut.

---

## 2. Cara 1: Menjalankan Tanpa Headset VR (Mouse & Keyboard di PC/Laptop)

Proyek ini telah dilengkapi dengan **`EditorSimPlatform`** dan pintasan (*shortcuts*) **Mouse + Keyboard** khusus Unity Editor sehingga Anda dapat menguji seluruh alur permainan hanya menggunakan PC/Laptop tanpa headset VR:

### Langkah-Langkah Menjalankan:
1. Pastikan scene **`Assets/_Project/Scenes/00_Boot.unity`** sedang terbuka.
2. Tekan tombol **Play (▶)** di bagian atas tengah Unity Editor.
3. Gunakan tab **Game View** untuk melihat antarmuka (UI) yang berada `1.15 meter` di depan kamera.

### Tabel Kontrol Mouse & Keyboard di Play Mode (Tanpa Headset VR):

| Aksi / Fitur yang Diuji | Kontrol di PC / Laptop (Game View) | Penjelasan |
| :--- | :--- | :--- |
| **Klik Tombol Menu UI** | **Klik Kiri Mouse** langsung pada tombol di *Game View* | Kanvas World-Space VR mendukung klik mouse biasa di Editor (`GraphicRaycaster`). |
| **Konfirmasi Langkah Kalibrasi (7 Langkah)** | Tekan **`Spacebar`** atau klik tombol **`Confirm Step (Trigger)`** | Saat tidak ada stik VR yang terhubung, sistem otomatis menyimulasikan posisi duduk, dada, bahu, jangkauan tangan kiri/kanan (`0.60 m`), dan pangkuan (*lap*) yang valid. |
| **Menggerakkan Tangan Kiri Secara Manual** | Tahan tombol **`Q`** + **Gerakkan Mouse** *(Scroll Mouse = Maju/Mundur)* | Menggerakkan bola tangan kiri (`LeftHandTip`) di ruang 3D depan kamera. |
| **Menggerakkan Tangan Kanan Secara Manual** | Tahan tombol **`E`** + **Gerakkan Mouse** *(Scroll Mouse = Maju/Mundur)* | Menggerakkan bola tangan kanan (`RightHandTip`) di ruang 3D depan kamera. |
| **Memukul / Menyentuh Target Aktif Otomatis** | Tekan tombol **`Tab`** saat latihan berlangsung | Tangan yang sesuai (`Left`/`Right`) otomatis bergerak cepat menyentuh/menekan target aktif (mendukung *Forward Press* `0.03 m` dan *Seated Boxing* `> 0.30 m/s`). |
| **Pause / Resume Manual (`S-1`)** | Tekan tombol **`Esc` (Escape)** | Membuka layar *Paused* dan menguji hitung mundur *Resume* 3 detik (`GP-FLOW-02`). |
| **Simulasi Auto-Pause Tangan di Pangkuan (`S-2`)** | Tekan tombol **`L`** saat latihan berlangsung, lalu diamkan **2 detik** | Memindahkan kedua tangan ke titik pangkuan (`LapPoint`). Setelah 2 detik, game akan otomatis *Pause* dan menampilkan layar keselamatan. |
| **Simulasi Headset Recenter (`S-5`)** | Tekan tombol **`R`** saat latihan berlangsung | Memicu event `TrackingOriginRecentered` sehingga game otomatis *Pause* dan meminta konfirmasi ulang posisi duduk (*Quick Recenter*). |
| **Menggeser Posisi Kepala / Tangan via Scene View** | Buka tab **Scene**, pilih objek `Main Camera`, `Left Controller`, atau `Right Controller`, lalu geser gizmo panahnya | Cocok untuk menguji indikator miring tubuh (*Lateral Lean* `|Δx| > 0.20 m` selama `0.5 detik` dengan menggeser `Main Camera` pada sumbu X). |

---

## 3. Cara 2: Menjalankan Langsung di Headset Meta Quest Tanpa Build APK (Quest Link / Air Link)

Jika Anda memiliki headset **Meta Quest 2 / Quest 3 / Quest 3S** dan ingin mencobanya langsung di headset **tanpa melakukan proses Build APK yang memakan waktu lama**, Anda dapat melakukan *streaming* langsung dari Unity Editor:

### Prasyarat:
1. Instal aplikasi **Meta Quest Link** di PC Windows Anda.
2. Buka aplikasi **Meta Quest Link** di PC:
   - Masuk ke **Settings > General**.
   - Aktifkan **Unknown Sources**.
   - Pastikan **OpenXR Runtime** disetel sebagai **Active** (*Meta Quest Link as active OpenXR runtime*).
3. Hubungkan headset Meta Quest ke PC menggunakan kabel USB-C (**Quest Link**) atau Wi-Fi 5GHz (**Air Link**), lalu masuk ke tampilan **Rift / Quest Link Home** di dalam headset.

### Langkah Menjalankan dari Unity Editor:
1. Di Unity Editor, pastikan Anda sudah menjalankan **`ZenoFit > 1. Run Full VR Project Setup`** (yang mengaktifkan **OpenXR** pada tab *Standalone / PC* sekaligus *Android*).
2. Buka scene **`Assets/_Project/Scenes/00_Boot.unity`**.
3. Kenakan headset Meta Quest Anda dan pegang kedua kontroler Touch.
4. Klik tombol **Play (▶)** di Unity Editor.
5. Game akan langsung tampil di dalam headset Meta Quest Anda secara *real-time*! Setiap perubahan kode atau pengaturan di Inspector dapat langsung diuji dalam hitungan detik tanpa perlu *Build APK*.

---

## 4. Cara 3: Menjalankan Pengujian Otomatis (Unit Tests AT-01 s/d AT-16)

Untuk memastikan seluruh rumus matematika kalibrasi, deteksi tabrakan anti-tembus (*segment-to-sphere*), kelima latihan, tempo adaptif, skor, penyimpanan JSON, hingga sistem keselamatan berjalan sesuai spesifikasi tanpa membuka mode VR:

1. Klik menu **`ZenoFit > 6. Open Test Runner`** (atau melalui menu **`Window > General > Test Runner`**).
2. Pilih tab **EditMode** di bagian atas jendela *Test Runner*.
3. Klik tombol **Run All**.
4. Seluruh 16 pengujian penerimaan (**`AT-01` s/d `AT-16`**) pada [`AcceptanceTests.cs`](../Assets/_Project/Tests/EditMode/AcceptanceTests.cs) akan dieksekusi dalam waktu kurang dari 1 detik.

---

## 5. Lokasi File Data Lokal (JSON Persistence)

Saat Anda menjalankan game secara lokal di Unity Editor, file profil kalibrasi, riwayat sesi latihan, dan pengaturan disimpan secara lokal (tanpa internet/cloud) di folder `Application.persistentDataPath` Windows Anda:

```text
C:\Users\<NamaUserAnda>\AppData\LocalLow\DefaultCompany\ZenoFit\
├── calibration_profile.json   (Data kalibrasi jangkauan tangan, dada, bahu, & zona rintangan kursi roda)
├── sessions.json              (Riwayat hingga 500 sesi latihan terakhir)
└── settings.json              (Pengaturan tingkat kesulitan, mode satu/dua tangan, volume, & haptik)
```

- Anda dapat membuka ketiga file `.json` tersebut menggunakan Notepad / VS Code untuk memeriksa atau mengubah data secara langsung.
- Anda juga dapat menghapus seluruh data tersimpan langsung dari dalam game melalui tombol **Delete Saved Data (Reset)** di layar **Main Menu**.

---

## 6. Pemecahan Masalah Umum (Troubleshooting)

- **Menu `ZenoFit` belum muncul di bagian atas Unity Editor:**
  - Klik di dalam jendela Unity Editor agar Unity melakukan *auto-refresh* dan mengompilasi skrip baru, atau tekan **`Ctrl + R`**.
- **Muncul pesan peringatan kuning (Warning) lama di Console:**
  - Klik tombol **Clear** di pojok kiri atas tab **Console**.
- **Tombol UI tidak bisa diklik saat Play Mode di PC:**
  - Pastikan Anda mengklik di dalam tab **Game** (bukan tab *Scene*), dan pastikan tidak sedang menahan tombol `Q` atau `E`.
- **Ingin mengulang Kalibrasi dari awal:**
  - Pada layar **Main Menu** atau **Exercise Select**, klik tombol **Recalibrate**, atau klik **Delete Saved Data (Reset)**.

