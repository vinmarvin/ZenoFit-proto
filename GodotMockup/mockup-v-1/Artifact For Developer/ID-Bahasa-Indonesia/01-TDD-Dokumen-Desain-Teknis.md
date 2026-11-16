# ZenoFit (Godot 4.x) — Dokumen Desain Teknis (TDD)

**Proyek**: Mockup Exergame VR Duduk ZenoFit (`mockup-v-1`)  
**Engine**: Godot Engine 4.x (`gl_compatibility` / Mobile OpenXR)  
**Target Platform**: **PICO 4 Ultra** (Standalone Android OpenXR + PCVR PICO Connect / WiVRn / ALVR), **Meta Quest 3 / 3S / 2** (Standalone Android OpenXR + Quest Link), dan **Simulator Desktop Mouse-Keyboard**  
**Pernyataan Non-Klinis**: *ZenoFit adalah game kebugaran dan kebugaran ringan VR dalam posisi duduk. Bukan perangkat medis ("Not a medical device"). Hentikan permainan jika Anda merasakan nyeri, pusing, atau ketidaknyamanan.*

---

## 1. Ringkasan Eksekutif & Tujuan Desain Utama

ZenoFit adalah game kebugaran arcade VR dalam posisi duduk (*seated VR*) yang dirancang di sekitar **Profil Kenyamanan (*Comfort Profile*)** individual, nol pergerakan kamera buatan (*zero artificial locomotion*), serta batas keamanan fisik yang ketat. Setiap posisi target, sudut, dan ambang batas dihitung secara matematis dari postur duduk pemain yang telah dikalibrasi, bukan koordinat ruang dunia yang kaku.

### Pilar Teknis Utama
1. **Ruang Referensi Duduk Saja (`XR_REFERENCE_SPACE_TYPE_LOCAL`)**: Titik asal kamera (`XROrigin3D`) bersifat permanen dan stasioner (`position == Vector3.ZERO`, `rotation == Vector3.ZERO`). Tidak pernah ada translasi, rotasi, atau guncangan kamera buatan.
2. **Kerangka Koordinat Setara Antar-Engine (`SpecSpace` ↔ `BodyFrame`)**: Semua persamaan spesifikasi menggunakan kerangka duduk tangan-kiri (*left-handed*) `+Z` ke depan (`SpecSpace`) sehingga setiap rumus numerik 100% identik dengan spesifikasi Unity, sementara `SpecSpace` mengonversi secara otomatis ke dan dari ruang dunia 3D Godot yang tangan-kanan (*right-handed*) `-Z` ke depan.
3. **Amplop Jangkauan Asimetris & Sadar-Rintangan (*Obstacle-Aware*)**: Lengan kiri dan kanan dikalibrasi secara independen (`R_f,L`, `R_f,R`, `R_oh,L`, `R_oh,R`, `R_s,L`, `R_s,R`). Sandaran tangan kursi, meja, dan baki kursi roda direkam sebagai bola eksklusi 3D (`r_ex = 0.12 m`) dan dihindari secara otomatis saat target dimunculkan (*spawn*).
4. **Keamanan Fisik Bertingkat (Level A vs. Level B)**:
   - **Level A (Hanya Anggota Tubuh Bagian Atas)**: `M01`–`M07` hanya memerlukan gerakan bahu, siku, dan pergelangan tangan di dalam kerangka duduk.
   - **Level B (Batang Tubuh / Kepala / Keseimbangan)**: `M08` (Rotasi Leher / *Neck Yaw*), `M09` (Rotasi Batang Tubuh / *Trunk Rotation*), dan `M10` (Condong Samping / *Lateral Trunk Lean*) memerlukan konfirmasi kursi stabil sebelum diaktifkan, tidak pernah dijadwalkan berurutan dalam mode *Score Attack*, dan dikecualikan sepenuhnya saat **Mode Tanpa-Batang-Tubuh (*No-Trunk Mode*)** diaktifkan.
5. **Gameplay 100% Tanpa Tombol saat Ronde Aktif**: Ronde latihan aktif hanya menggunakan pose 6DoF kepala dan tangan (`HandTip_L` dan `HandTip_R`) — tidak memerlukan penekanan tombol *trigger* atau *grip* selama ronde berlangsung.

---

## 2. Sistem Koordinat & Kerangka Tubuh Duduk (`BodyFrame`)

### 2.1 SpecSpace vs. Ruang Dunia Godot
Diimplementasikan di [`core/spec_space.gd`](../../core/spec_space.gd) dan [`core/body_frame.gd`](../../core/body_frame.gd):

| Sumbu / Besaran | Spec Space (`MarkdownGuideForAIReconstruction`) | Ruang 3D Godot (`Node3D`) | Rumus Konversi (`SpecSpace`) |
| :--- | :--- | :--- | :--- |
| **Kanan (`X`)** | `+X` = Kanan Pemain | `+X` = Kanan | `godot.x = spec.x` |
| **Atas (`Y`)** | `+Y` = Atas | `+Y` = Atas | `godot.y = spec.y` |
| **Depan (`Z`)** | `+Z` = Depan (di depan dada) | `-Z` = Depan | `godot.z = -spec.z` |
| **Yaw (`ψ`)** | `+ψ` = Searah jarum jam dari atas (menoleh ke kanan) | `+rotation.y` = Berlawanan jarum jam (menoleh ke kiri) | `godot_yaw = -spec_yaw` |

### 2.2 Konstruksi `BodyFrame`
Selama Kalibrasi Dasar Langkah 1 (Pose Duduk Netral), sistem mengambil sampel posisi dan arah kepala:
- **Titik Asal Dada (`O_body`)**:
  $$O_{\text{body}} = \bar{p}_{\text{head}} - (0, h_{\text{neck}}, 0), \quad h_{\text{neck}} = 0.25\text{ m}$$
- **Sumbu Depan (`Z_body`)**: Proyeksi horizontal dari vektor depan kepala:
  $$Z_{\text{body}} = \text{normalize}\big((\bar{f}_x, 0, \bar{f}_z)\big)$$
- **Sumbu Atas (`Y_body`)**: `(0, 1, 0)`
- **Sumbu Kanan (`X_body`)**: `Y_body × Z_body` (di dalam `SpecSpace` tangan-kiri)

---

## 3. Sistem Kalibrasi & Profil Kenyamanan (`ComfortProfile`)

Diimplementasikan di [`calibration/calibration_controller.gd`](../../calibration/calibration_controller.gd) dan [`core/comfort_profile.gd`](../../core/comfort_profile.gd).

### 3.1 Kalibrasi Dasar (6–7 Langkah — Pengguna Baru atau Kalibrasi Ulang Penuh)
1. **Langkah 1 — Pose Duduk Netral**: Menetapkan `O_body`, `Z_body`, dan jangkar kursi `seat_anchor_local_spec`.
2. **Langkah 2 — Jangkauan Nyaman Lengan Kiri**: Mengukur `R_f,L` dan `R_s,L` secara independen.
3. **Langkah 3 — Jangkauan Nyaman Lengan Kanan**: Mengukur `R_f,R` dan `R_s,R` secara independen.
4. **Langkah 4 — Jangkauan Nyaman ke Atas (*Overhead*)**: Mengukur ketinggian nyaman di atas kepala (`R_oh`, dibatasi agar elevasi pandangan `<= 45°`).
5. **Langkah 5 — Zona Istirahat / Pangkuan (*Lap Point*)**: Mencatat posisi istirahat tangan di pangkuan (`lap_point_from_chest_m`).
6. **Langkah 6 — Penandaan Rintangan Kursi / Meja (*Opsional*)**: Menyimpan titik rintangan `c_i` sebagai bola eksklusi berjari-jari `r_ex = 0.12 m`.

### 3.2 Pemeriksaan Cepat Pengguna Lama (*Returning-User Quick Check* `<= 15 dtk`)
- Memperbarui `O_body` dan `Z_body` dengan **1 kali konfirmasi duduk** sambil mempertahankan jarak jangkauan lengan dan profil kenyamanan yang sudah tersimpan di `comfort_profile.json`.

### 3.3 Kalibrasi Spesifik Modul (Level B)
- **Rotasi Leher (`M08`)**: Mencatat sudut menoleh kiri/kanan yang nyaman (`ψ_max,L`, `ψ_max,R`,デフォルト `45°`).
- **Rotasi Batang Tubuh (`M09`)**: Mencatat sapuan rotasi torso kiri/kanan.
- **Condong Samping (`M10`)**: Mencatat pergeseran kepala lateral kiri/kanan (`Δx_max,L`, `Δx_max,R`, dibatasi hingga `<= 0.30 m`).

---

## 4. Mode Permainan, Undian Sesi, & Mesin Status (*State Machine*)

Diimplementasikan di [`autoload/game_flow.gd`](../../autoload/game_flow.gd) dan [`core/session_draw.gd`](../../core/session_draw.gd):
- **3 Kelompok Tubuh Seimbang**:
  - **Kelompok 1 (`UPPER_PUSH_STRIKE`)**: `M01`, `M04`, `M06`, `M09`
  - **Kelompok 2 (`SHOULDER_OVERHEAD_REACH`)**: `M02`, `M03`, `M05`, `M07`
  - **Kelompok 3 (`NECK_TRUNK_BALANCE`)**: `M08`, `M10`
- **Aturan Undian 5 Ronde (*Score Attack*)**:
  1. Memilih 5 mekanik berbeda yang mencakup ketiga kelompok tubuh (kecuali jika *No-Trunk Mode* aktif).
  2. Menerapkan bobot `×0.5` pada mekanik yang baru dimainkan di sesi sebelumnya agar variasi tetap segar.
  3. **Mode Tanpa-Batang-Tubuh (*No-Trunk Mode*)**: Mengecualikan seluruh mekanik Level B (`M08`, `M10`).
  4. **Substitusi Kursi Stabil**: Jika pemain menolak konfirmasi kursi stabil sebelum mekanik Level B dimulai, mekanik Level B tersebut otomatis diganti dengan mekanik Level A yang belum terpakai.

---

## 5. Spesifikasi Matematis 10 Mekanik Latihan (`M01`–`M10`)

Dievaluasi di [`core/mechanics_math.gd`](../../core/mechanics_math.gd) dan divisualisasikan di [`mechanics/`](../../mechanics/):

1. **`M01` — Asteroid Brawler (Tinju ke Depan)**:
   - Level A | Deteksi segmen-ke-bola anti-tunnelling pada bidang pukul `z_hit = k * R_f,h`. Pukulan dengan kecepatan `>= 0.30 m/s` mendapat **Bonus Pukulan Mantap (`+25 poin`)**.
2. **`M02` — Space Fruit Harvester (Jangkauan Atas & Tarik ke Keranjang)**:
   - Level A | Menahan tangan di buah angkasa (`y = k * R_oh * sin(40°)`, `z = k * R_oh * cos(40°)`) selama `0.40 dtk` lalu memasukkannya ke keranjang pangkuan.
3. **`M03` — Glider Pilot (Rentang Lengan Dua Tangan / *T-Pose*)**:
   - Level A | Mengemudikan pesawat layang melewati cincin menggunakan rentang samping kedua tangan (`x = ±k * R_s,h`) dan kemiringan pergelangan tangan.
4. **`M04` — Turret Gunner (Rotasi Bahu & Bidikan Tahan)**:
   - Level A | Mengunci target drone pada sudut yaw `±85% * ψ_max` (batas `<= 6°`) selama `0.50 dtk`.
5. **`M05` — Cosmic Tug-of-War (Tarikan Dayung Duduk Dua Tangan)**:
   - Level A | Menarik jangkar energi dari `z_reach = k * R_f` ke dekat dada `z_chest = 0.15 m` dengan pengali proporsional `g_h = 0.35 / (k * R_f,h - 0.15)`.
6. **`M06` — Force Blast (Dorongan Dada Dua Tangan Sinkron)**:
   - Level A | Mengisi daya di dekat dada (`z <= 0.20 m`) lalu mendorong kedua tangan ke bidang ekstensi `z_ext = k * min(R_f,L, R_f,R)`.
7. **`M07` — Shield Generator Crank (Putaran Engkol Bahu)**:
   - Level A | Memutar roda engkol berjari-jari `r_w = 0.18 m` pada irama target `f_target` (`0.50 / 0.75 / 1.00 Hz` ±25%).
8. **`M08` — Recon Scanner (Rotasi Leher / *Cervical Yaw* Terkontrol)**:
   - **Level B** | Menolehkan kepala secara halus untuk memindai suar selama `0.80 dtk` (timer jeda tanpa mereset jika keluar sedikit). Menampilkan pengingat *"Gerakkan kepala lebih perlahan"* jika kecepatan sudut kepala `> 60°/dtk`.
9. **`M09` — Potion Brewer (Adukan Kawah & *Bicep Curl* bergantian)**:
   - Level A | Mengaduk kawah dengan pelacakan pegas teredam (`α = 1 - e^(-dt / 0.15)`) serta menjatuhkan bahan dengan gerakan *bicep curl* (`0.35 * L_arm` hingga `0.85 * L_arm`).
10. **`M10` — Laser Evader (Condong Batang Tubuh Lateral Terkontrol)**:
    - **Level B** | Menggeser kepala ke celah dinding pada `g = ±k * Δx_max,dir` (toleransi `±0.08 m`) sambil menjaga agar pergeseran tidak melebihi ambang keamanan `min(Δx_max + 0.05 m, 0.30 m)`.

---

## 6. Penilaian (*Scoring*), Multiplier Kombo, & Tempo Adaptif

Diimplementasikan di [`core/scoring.gd`](../../core/scoring.gd) dan [`core/adaptive_tempo.gd`](../../core/adaptive_tempo.gd):
- **Skor Dasar & Ketepatan Waktu**:
  $$P_{\text{base}} = 100 + \lfloor 50 \cdot (1 - \text{clamp}(t_{\text{hit}} / T_{\text{life}}, 0, 1)) \rfloor$$
- **Multiplier Kombo**:
  $$M_{\text{combo}} = 1.0 + 0.1 \cdot \min(\text{streak\_sebelum}, 5) \quad (\text{maks } 1.5\times)$$
- **Tempo Adaptif (`AdaptiveTempo`)**: Mengevaluasi jendela 8 target terakhir:
  - Rasio kena `>= 85%` → `+5 BPM`
  - Rasio kena `< 60%` → `-5 BPM`

---

## 7. Pemantau Keamanan (*Safety Monitors*)

Diimplementasikan di [`safety/safety_monitors.gd`](../../safety/safety_monitors.gd):
1. **Jeda Otomatis Tangan di Pangkuan (`AutoPauseMonitor`)**: Menjeda otomatis jika kedua tangan berada di dalam radius `0.15 m` dari `LapPoint` selama `>= 2.0 detik`.
2. **Peringatan Condong Berlebih (`LeanMonitor`)**: Menjeda otomatis jika kepala bergeser secara horizontal `> 0.20 m` selama `>= 0.5 detik` pada mekanik Level A (atau melebihi `min(Δx_max + 0.05 m, 0.30 m)` pada `M10`).
3. **Pengingat Istirahat (`RestReminderMonitor`)**: Menampilkan pengingat istirahat leher/bahu setelah `8 menit` waktu latihan aktif.
