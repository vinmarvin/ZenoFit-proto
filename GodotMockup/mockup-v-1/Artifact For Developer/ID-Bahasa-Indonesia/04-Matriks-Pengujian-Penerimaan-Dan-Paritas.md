# ZenoFit (Godot 4.x) — Matriks Pengujian Penerimaan (`AT-01`..`AT-28`) & Paritas Unity-ke-Godot

Dokumen ini memetakan setiap persyaratan dalam [`16-acceptance-tests.md`](../../MarkdownGuideForAIReconstruction/16-acceptance-tests.md) dan [`03-godot-build.md`](../../MarkdownGuideForAIReconstruction/03-godot-build.md) ke implementasi kode dan pengujian otomatis di [`tests/test_acceptance_suite.gd`](../../tests/test_acceptance_suite.gd).

---

## 1. Cara Menjalankan Pengujian Otomatis

```bash
/usr/bin/godot --headless --xr-mode off --path /home/ramirez/XR/GodotMockup/mockup-v-1 -s res://tests/run_acceptance_tests.gd
```

Hasil verifikasi: **68 LULUS (`PASS`), 0 GAGAL (`FAIL`)**.

---

## 2. Matriks Hasil Pengujian Penerimaan (`AT-01`..`AT-28`)

| ID Uji | Persyaratan Spesifikasi | File Implementasi | Status |
| :--- | :--- | :--- | :--- |
| **SPEC-SPACE** | Konversi ruang tangan-kiri Spec (`+Z` depan, `+ψ` kanan) ↔ ruang tangan-kanan Godot (`-Z` depan, `+rotation.y` kiri) | [`core/spec_space.gd`](../../core/spec_space.gd), [`core/body_frame.gd`](../../core/body_frame.gd) | **LULUS (PASS)** |
| **AT-01** | `M01` Asteroid Brawler: bidang pukul `z_hit = k * R_f` (`0.510 m`) & skala kecepatan berdasarkan jangkauan lengan | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-02** | `M03` Glider Pilot: rentang tangan `x = 0.442 m`, `y = -0.255 m`, kemiringan `5.71°`, dan kecepatan lateral `0.571 m/s` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-03** | `M02` Space Fruit Harvester: posisi buah atas (`y = 0.481 m`, `z = 0.361 m`) dan batas sudut pandang `<= 45°` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-04** | Bola Eksklusi Rintangan (`r_ex = 0.12 m`): menolak kandidat di dalam rintangan dan mencarikan posisi aman | [`core/comfort_profile.gd`](../../core/comfort_profile.gd) | **LULUS (PASS)** |
| **AT-05** | Interval spawn berdasarkan BPM (`60 BPM -> 1.0 dtk`, `75 BPM -> 0.8 dtk`) | [`core/adaptive_tempo.gd`](../../core/adaptive_tempo.gd) | **LULUS (PASS)** |
| **AT-06** | Tempo Adaptif pada jendela 8 target (`87.5% -> +5 BPM`, `75% -> tetap`, `50% -> -5 BPM`) | [`core/adaptive_tempo.gd`](../../core/adaptive_tempo.gd) | **LULUS (PASS)** |
| **AT-07** | Skor ketepatan waktu per target (`lifetime = 2.0 dtk`, `t_hit = 0.5 dtk` → `137 poin`) | [`core/scoring.gd`](../../core/scoring.gd) | **LULUS (PASS)** |
| **AT-08** | Akumulasi skor ronde, akurasi (`80%`), dan multiplier kombo (`526 poin`) | [`core/scoring.gd`](../../core/scoring.gd) | **LULUS (PASS)** |
| **AT-09** | Jeda Otomatis Pangkuan (*Auto-Pause Lap*): memicu jeda tepat setelah kedua tangan berada di `LapPoint` selama `2.0 dtk` | [`safety/safety_monitors.gd`](../../safety/safety_monitors.gd) | **LULUS (PASS)** |
| **AT-10** | Peringatan Condong Berlebih: jeda setelah `0.5 dtk` saat `|Δx| > 0.20 m` (dan override `M10` `min(Δx_max + 0.05, 0.30)`) | [`safety/safety_monitors.gd`](../../safety/safety_monitors.gd) | **LULUS (PASS)** |
| **AT-11** | Mode Satu Tangan (*One-Handed Accessibility*): menonaktifkan tangan kanan memaksa mode `LEFT_ONLY` | [`core/comfort_profile.gd`](../../core/comfort_profile.gd) | **LULUS (PASS)** |
| **AT-12** | Ambang pukulan `M01`: pukulan mantap (`>= 0.30 m/s`) memberi bonus `+25`, pukulan ringan tetap dihitung tanpa gagal | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-13** | Deteksi tabrakan segmen-ke-bola anti-tunnelling menangkap pukulan cepat dalam 1 frame | [`core/geometry.gd`](../../core/geometry.gd) | **LULUS (PASS)** |
| **AT-14** | Jeda instan dalam 1 frame & pembekuan timer ronde saat dijeda | [`autoload/game_flow.gd`](../../autoload/game_flow.gd) | **LULUS (PASS)** |
| **AT-15** | Penyimpanan JSON lokal & Pemeriksaan Cepat Pengguna Lama (`<= 15 dtk` dalam 1 konfirmasi) | [`autoload/save_service.gd`](../../autoload/save_service.gd), [`calibration/calibration_controller.gd`](../../calibration/calibration_controller.gd) | **LULUS (PASS)** |
| **AT-16** | Event *Recenter* menjeda ronde aktif dan meminta konfirmasi ulang posisi duduk | [`autoload/platform.gd`](../../autoload/platform.gd), [`main.gd`](../../main.gd) | **LULUS (PASS)** |
| **AT-19** | `M04` Turret Gunner: posisi sudut drone (`42.5°`, `x = 1.013 m`, `z = 1.106 m`) dan penguncian bidikan `<= 6°` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-20** | `M05` Cosmic Tug-of-War: pengali tarikan proporsional untuk jangkauan asimetris (`0.476` vs `0.866`) | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-21** | `M06` Force Blast: rasio muatan `0.75` (`75 poin`) dan bidang ekstensi dua tangan `min(R_f,L, R_f,R) * k = 0.315 m` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-22** | `M07` Shield Crank: toleransi irama putaran `±25%` dan kecepatan tangensial `0.848 m/s` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-23** | `M08` Recon Scanner: timer tahan (*dwell*) dijeda tanpa mereset & pengingat kecepatan kepala `> 60°/dtk` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-24** | `M09` Potion Brewer: konstanta pelacakan pegas `6.7%` per frame, lag `0.10 m`, dan rentang *bicep curl* | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-25** | `M10` Laser Evader: pusat celah `0.238 m`, gagal saat melebihi batas keamanan `0.30 m`, berhasil pada `0.22 m` | [`core/mechanics_math.gd`](../../core/mechanics_math.gd) | **LULUS (PASS)** |
| **AT-26** | Undian Sesi 5 Ronde mencakup 3 kelompok tubuh & *No-Trunk Mode* mengecualikan seluruh mekanik Level B | [`core/session_draw.gd`](../../core/session_draw.gd) | **LULUS (PASS)** |
| **AT-27** | Multiplier kombo pada `streak = 10` (`1.5x` cap) mengubah skor dasar `137` menjadi `205 poin` | [`core/scoring.gd`](../../core/scoring.gd) | **LULUS (PASS)** |
| **AT-28** | Menolak konfirmasi kursi stabil mengganti mekanik Level B dengan mekanik Level A yang belum dipakai | [`core/session_draw.gd`](../../core/session_draw.gd), [`autoload/game_flow.gd`](../../autoload/game_flow.gd) | **LULUS (PASS)** |
| **MASCOT** | `Floating Mascots.glb` memuat hierarki 3D, menganimasikan ke-10 demo latihan, dan bereaksi saat disentuh tangan | [`mascot/floating_mascot_coach.gd`](../../mascot/floating_mascot_coach.gd) | **LULUS (PASS)** |
