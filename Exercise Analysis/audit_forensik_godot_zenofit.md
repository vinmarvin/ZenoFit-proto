# Audit Forensik Implementasi & Silsilah Desain Latihan VR Duduk (*ZenoFit*) — Fokus Godot 4.7

> [!IMPORTANT]
> **Status Audit & Lingkup Verifikasi Kode (*Codebase Scope*)**
> - **Mode Audit**: *Strict Read-Only* (tidak ada file kode, skrip, catatan, atau aset di dalam direktori proyek `/home/ramirez/XR-FP` maupun `/home/ramirez/XR` yang dibuat, diubah, atau dihapus).
> - **Fokus Utama**: Basis kode **Godot 4.7 (`GodotMockup/mockup-v-1/`)** yang mengimplementasikan **10 mekanik latihan (`M01`–`M10`)** berbasis *Score Attack* (5 ronde × 30 detik) dan *Practice Mode* dalam bahasa GDScript.
> - **Konteks Dual-Codebase (`VERIFIED_IN_CODE`)**: Di repositori proyek terdapat prototipe awal berbasis **Unity 6 (`ZenoFit/Assets/_Project/`)** yang mengimplementasikan 5 latihan berbasis ketukan (*beat-based* 3 ronde × 20 target) dalam C#. Namun, seluruh gameplay aktif terbaru, sistem kalibrasi mandiri, dan pengujian penerimaan (*acceptance tests* `AT-01`–`AT-28`) diimplementasikan di **Godot 4.7**. Dokumen audit ini membedah implementasi Godot 4.7 secara tuntas dan membandingkannya terhadap draf spesifikasi Markdown.
> - **Aturan Hierarki Kebenaran (*Source of Truth*)**:
>   1. Logika runtime kode GDScript & scene `.tscn` / resource `.tres`.
>   2. Riwayat Git (`git log`, `git show ace93a7b`, `git show 9a93059`).
>   3. Draf spesifikasi Markdown di [MarkdownGuideForAIReconstruction/](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/) dan dokumen ideasi awal di [Ideation/](file:///home/ramirez/XR-FP/Ideation/) *(hanya diperlakukan sebagai petunjuk draf yang belum terverifikasi, bukan bukti)*.

---

## Glosarium Istilah Teknis (Untuk Mahasiswa Informatika)

Saat pertama kali istilah teknis muncul di dokumen ini, penjelasan disertakan:
- **`3DoF` (*3 Degrees of Freedom*)**: Pelacakan rotasi 3 sumbu saja (*yaw* = menggeleng kiri/kanan, *pitch* = mengangguk atas/bawah, *roll* = memiringkan kepala/tangan ke samping) tanpa memperhitungkan perpindahan posisi translasi $(x, y, z)$ di ruang fisik.
- **`6DoF` (*6 Degrees of Freedom*)**: Pelacakan rotasi 3 sumbu sekaligus translasi posisi 3 dimensi $(x, y, z)$ secara penuh di ruang nyata.
- **`BodyFrame` (Kerangka Koordinat Tubuh)**: Sistem koordinat lokal pemain yang titik pusatnya $(0,0,0)$ diikat pada titik dada (*sternum*) pemain saat duduk, dengan sumbu $+Z$ menghadap lurus ke arah depan dada pemain.
- **`SpecSpace` (Ruang Koordinat Spesifikasi)**: Konvensi koordinat tangan-kiri (*left-handed*, $+X$ kanan, $+Y$ atas, $+Z$ depan) yang digunakan di seluruh rumus matematis internal game sebelum dikonversi ke koordinat dunia Godot ($-Z$ depan, tangan-kanan / *right-handed*).
- **`Reach Envelope` (Amplop Jangkauan Aman)**: Ruang volume 3D di sekitar tubuh pemain tempat target latihan diizinkan muncul, dibatasi maksimal $85\%$ ($k \le 0.85$) dari jangkauan lengan nyaman hasil kalibrasi.
- **`Anti-Tunnelling` (Deteksi Tabrakan Segmen-ke-Bola)**: Algoritma pengecekan jarak terdekat antara garis lintasan tangan frame sebelumnya ke frame saat ini ($\vec{P}_{t-\Delta t} \to \vec{P}_t$) terhadap pusat bola target, mencegah pukulan berkecepatan tinggi "menembus" target tanpa terdeteksi di antara dua frame rendering.
- **`Dwell Time` (Waktu Tahan Bidikan)**: Durasi waktu minimum (dalam detik) di mana pemain harus mempertahankan orientasi arah kepala atau posisi tangan di dalam ambang toleransi target agar aksi dinyatakan berhasil.
- **`Hysteresis` (Histeresis Ambang Ganda)**: Logika dua ambang batas (tekan dan lepas) yang mewajibkan tangan ditarik mundur melewati ambang luar sebelum penekanan tombol/bidang berikutnya dapat dihitung kembali.

---

## STEP 1 — INVENTARISASI SELURUH MEKANIK LATIHAN (*EXERCISE INVENTORY*)

Berikut adalah status implementasi setiap mekanik latihan yang ditemukan di kode sumber Godot 4.7, scene `main.tscn`, resource kesulitan, draf Markdown, maupun dokumen ideasi awal:

| Kode / ID | Nama di Kode | Nama di Markdown | Status Implementasi | Bukti Lokasi File & Fungsi (`VERIFIED_IN_CODE`) |
| :--- | :--- | :--- | :--- | :--- |
| **`M01`** | `M01AsteroidBrawler` | *M01 — Seated Boxing ("Asteroid Brawler")* | **`FULLY_IMPLEMENTED`** | `VERIFIED_IN_CODE`: [m01_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd), fungsi `_spawn_asteroid()`, `update_mechanic()`, dan `MechanicsMath.m01_compute_asteroid_params()` di [mechanics_math.gd:10](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L10). |
| **`M02`** | `M02FruitHarvester` | *M02 — Overhead Reach ("Fruit Harvester")* | **`FULLY_IMPLEMENTED`** | `VERIFIED_IN_CODE`: [m02_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m02_fruit_harvester/m02_mechanic.gd), fungsi `_spawn_fruit()`, `_harvest_fruit()`, dan `MechanicsMath.m02_compute_fruit_placement()` di [mechanics_math.gd:34](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L34). |
| **`M03`** | `M03GliderPilot` | *M03 — Side Arm Raise ("Glider Pilot")* | **`PARTIAL`** | `VERIFIED_IN_CODE`: [m03_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L37-L78). Kemudi *roll* bekerja, tetapi validasi sudut abduksi `wings_ok` ($\theta \pm 15^\circ$) tidak dipanggil dan bonus $+10\text{ pts/s}$ diberikan tanpa syarat. |
| **`M04`** | `M04TurretGunner` | *M04 — Trunk Twist ("Turret Gunner")* | **`FULLY_IMPLEMENTED`** | `VERIFIED_IN_CODE`: [m04_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd), fungsi `update_mechanic()`, `m04_is_aim_locked()`, dengan ambang jarak dada $0.45\text{ m}$ (nuansa vs markdown $0.35\text{ m}$). |
| **`M05`** | `M05CosmicTugOfWar` | *M05 — Seated Row ("Cosmic Tug-of-War")* | **`PARTIAL`** | `VERIFIED_IN_CODE`: [m05_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L33-L48). Formula reduksi puing bekerja, tetapi `pick_hand_for_spawn(0)` mengunci evaluasi hanya pada tangan kiri pada mode 2 tangan dan tidak mengecek tombol *grip*. |
| **`M06`** | `M06ForceBlast` | *M06 — Forward Press ("Force Blast")* | **`FULLY_IMPLEMENTED`** | `VERIFIED_IN_CODE`: [m06_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m06_force_blast/m06_mechanic.gd), fungsi `update_mechanic()`, `_release_blast()`, dan `MechanicsMath.m06_compute_charge_and_points()` di [mechanics_math.gd:167](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L167). |
| **`M07`** | `M07ShieldCrank` | *M07 — Arm Circles ("Shield Generator Crank")* | **`PARTIAL`** | `VERIFIED_IN_CODE`: [m07_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L41-L70). Pita frekuensi radial bekerja untuk tangan kanan, tetapi tangan kiri diabaikan dan nilai mutlak `absf(d_angle)` membuat arah putaran tidak divalidasi. |
| **`M08`** | `M08ReconScanner` | *M08 — Neck Mobility and Far Focus ("Recon Scanner")* | **`PARTIAL`** | `VERIFIED_IN_CODE`: [m08_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd), fungsi `MechanicsMath.m08_step_scan_dwell()`. Validasi retikel yaw dan jeda kecepatan $>60^\circ/\text{s}$ bekerja, tetapi fitur jeda mata *Far-look break passthrough 20 s* tidak ada di kode. |
| **`M09`** | `M09PotionBrewer` | *M09 — Elbow Flexion and Wrist Pour ("Potion Brewer")* | **`PARTIAL`** | `VERIFIED_IN_CODE`: [m09_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L48-L84). Ambil bahan, *visual drag*, *curl* siku, dan rotasi pergelangan $\ge 60^\circ$ bekerja; tetapi posisi horizontal tangan di atas kawah tidak dicek saat menuang. |
| **`M10`** | `M10LaserEvader` | *M10 — Overhead Reach with Side Bend ("Laser Evader")* | **`PARTIAL`** | `VERIFIED_IN_CODE`: [m10_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L39-L72). Celah aman condong kepala $x_{\text{head}}$ bekerja, tetapi objek rel atas hanya visual (posisi tangan di rel atas tidak pernah divalidasi). |
| **—** | *(Tidak ada)* | *Shoulder Rolls (Rotasi Bahu)* | **`ONLY_IN_MARKDOWN`** | `ONLY_IN_MARKDOWN`: [Proposal-Unfixed.md](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L166-L167) (§A.1). Dihapus karena kamera headset tidak dapat melacak bahu naik-turun jika tangan diam; diganti oleh M07. |
| **—** | *(Tidak ada)* | *Seated Swimming Motion (Simulasi Renang)* | **`ONLY_IN_MARKDOWN`** | `ONLY_IN_MARKDOWN`: [Proposal-Unfixed.md](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L181-L182) (§B.7). Draf kardio berenang gaya dada duduk; tidak diimplementasikan di Godot maupun Unity. |
| **—** | *(Tidak ada)* | *Far-Look Break (20 s Passthrough Eye Relax)* | **`ONLY_IN_MARKDOWN`** | `ONLY_IN_MARKDOWN`: [10-m08-recon-scanner.md](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/10-m08-recon-scanner.md#L25) (§6.8.1). Usulan jeda relaksasi mata optik nyata; tidak diimplementasikan di kode runtime. |
| **—** | *(Tidak ada)* | *Elbow Flexion and Extension (Tarik & Kembali)* | **`ONLY_IN_MARKDOWN`** | `ONLY_IN_MARKDOWN`: [Proposal-Unfixed.md](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L172-L173) (§A.4). Gerakan murni fleksi-ekstensi siku; digabungkan ke dalam M09 (*Potion Brewer*). |

---

## STEP 2 — ANALISIS MENDALAM PER MEKANIK LATIHAN (GODOT 4.7)

---

### 1. `M01` — Seated Boxing ("Asteroid Brawler")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M01AsteroidBrawler` ([m01_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M01_ASTEROID_BRAWLER`, judul UI: `"M01: Asteroid Brawler (Seated Boxing)"` ([enums.gd:90](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L90)).
- **Di Markdown**: *M01 — Seated Boxing ("Asteroid Brawler")* ([03-m01-asteroid-brawler.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/03-m01-asteroid-brawler.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Shadow Boxing* lurus (*Jab* dan *Cross* bergantian ke depan) dalam kondisi duduk.
- **Bentuk Berdiri Penuh**: Melibatkan dorongan dari ujung kaki belakang, rotasi panggul dan pinggul (*hip rotation*), transmisi daya melalui tulang belakang toraks, protraksi tulang belikat (*scapular protraction*), ekstensi sendi siku (*elbow extension*), serta pronasi pergelangan tangan menjelang titik benturan.
- **Otot Target**: *Deltoideus anterior* (bahu depan), *pectoralis major* (dada), *triceps brachii* (lengan belakang), *serratus anterior* (stabilisator belikat), dan otot inti (*abdominal core/obliques*).
- **Tempo & Efektivitas**: Ritme $50\text{–}90\text{ BPM}$ secara berulang memicu peningkatan denyut jantung aerobik tanpa membebani persendian ekstremitas bawah.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Membaca posisi 3D tangan kiri dan kanan pada frame sebelumnya dan saat ini (`prev_left_local_spec`, `curr_left_local_spec`, `prev_right_local_spec`, `curr_right_local_spec`) di [m01_mechanic.gd:42-53](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd#L42-L53).
  - **Peringatan Saluran Input di Luar Desain Duduk**: Selama ronde aktif, [main.gd:228-253](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L228-L253) secara konstan membaca **`HEAD_POSITION` (translasi 3D headset `xr_camera.global_position`)** untuk `LeanMonitor` (jeda darurat jika condong $> 0.20\text{ m}$) serta penyesuaian tinggi vertikal `BodyFrame`.
- **API & Ruang Koordinat**:
  - Posisi dibaca dari node `XRController3D` (`LeftController` dan `RightController` di [main.tscn:10-14](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.tscn#L10-L14)) dengan tracker `&"left_hand"` dan `&"right_hand"`.
  - **Status Hand Tracking vs Controller Pose (`VERIFIED_IN_CODE`)**: Meskipun ekstensi OpenXR Hand Tracking aktif di file `project.godot:53-54`, node di scene adalah `XRController3D` biasa dan **tidak ada pembacaan `HAND_POSE` (kepalan tangan/fist)**. Tangan terbuka, jari telunjuk menunjuk, maupun kontroler fisik diperlakukan identik asalkan koordinat ujung tangan menyentuh bola target.
  - Koordinat dunia Godot dikonversi ke `SpecSpace` (+Z ke depan) dan dinormalisasi ke `BodyFrame` lokal via `GameFlow.body_frame.from_godot_world()` di [main.gd:238-239](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L238-L239).
- **Gerakan Diterima vs Ditolak**:
  - **Diterima**: Sapuan garis lintasan tangan yang sesuai dengan target (`LEFT` untuk asteroid biru `"L Punch"`, `RIGHT` untuk asteroid oranye `"R Punch"`). Kecepatan $\ge 0.30\text{ m/s}$ diklasifikasikan sebagai *Solid Hit*, sedangkan $< 0.30\text{ m/s}$ tetap diterima sebagai *Light Hit*.
  - **Ditolak**: Memukul asteroid kiri dengan tangan kanan (atau sebaliknya) ditolak secara otomatis oleh fungsi `ZenoGeometry.check_valid_hand_hit()` di [geometry.gd:40-43](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/geometry.gd#L40-L43) tanpa penalti skor.

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli (`EXTERNAL_KNOWLEDGE`)**: Pukulan tinju eksplosif dengan transfer momentum dari pijakan kaki dan putaran panggul.
2. **Kendala Posisi Duduk**: Pemain duduk di kursi atau kursi roda tidak memiliki tumpuan tolakan kaki; rotasi torso eksplosif dapat membahayakan stabilitas duduk di kursi putar (`STATED_IN_SOURCE`: [Proposal-Unfixed.md:46](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L46)); gerakan sentakan cepat dapat mencederai bahu pengguna kaku (`STATED_IN_SOURCE`: [Proposal-Unfixed.md:151](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L151)).
3. **Proksi di Dalam Game**: Asteroid diterbangkan dari jarak $z_0 = 1.5\text{ m}$ mendekati dada pemain menuju titik temu $z_{\text{hit}} = k \cdot R_{f,\text{hand}}$ pada jalur $x = \pm 0.10\text{ m}$ ([m01_mechanic.gd:70-79](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd#L70-L79)). Sebagai pengganti sensor impak beban fisik, kecepatan gerak rata-rata 3 frame ($\bar{v}$) dibandingkan terhadap ambang $0.30\text{ m/s}$ untuk memberikan bonus $+25\text{ poin}$ dan haptik getar lebih kuat (`0.70` selama `80 ms`).
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**:
   - Faktor jangkauan $k$: `0.60` (`Gentle`) $\to$ `0.75` (`Standard`) $\to$ `0.85` (`Active`) (`VERIFIED_IN_CODE`: [difficulty_preset.gd:26-48](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/difficulty_preset.gd#L26-L48)).
   - Radius target $r_t$: `0.12 m` $\to$ `0.10 m` $\to$ `0.08 m`.
   - Rentang tempo: `50–70 BPM` $\to$ `60–80 BPM` $\to$ `70–90 BPM`.
   - Umur target: `3 ketukan` ($3.60\text{ s}$ @ 50 BPM) $\to$ `2 ketukan` ($2.00\text{ s}$ @ 60 BPM dan $1.714\text{ s}$ @ 70 BPM).
   - **Alasan (`STATED_IN_SOURCE`)**: Aturan `GP-DIFF-01` dan `GP-ENV-01` di [00-gameplay-overview.md](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/00-gameplay-overview.md#L74) menetapkan bahwa tingkat kesulitan hanya boleh menaikkan jarak jangkauan hingga batas fisiologis $85\%$ kalibrasi serta mempersempit ukuran target, tanpa memicu gerakan menjauh dari sandaran kursi.
5. **Jejak Asal-Usul Ide**:
   - `STATED_IN_SOURCE`: Bermula dari draf penelitian pengguna kursi roda oleh David Ryan *Old Cynic* dan usulan Naufy §B.5 *"Seated Boxing"* di [Proposal-Unfixed.md:40-43, 178](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L40-L43).
   - `STATED_IN_SOURCE`: Masuk ke Git commit pertama `ace93a7b` sebagai `SeatedBoxingExercise.cs` (Unity) lalu ditransformasikan ke Godot 4.7 sebagai `M01AsteroidBrawler` dengan lintasan asteroid terbang.
6. **Vonis Fidelitas**: **`APPROXIMATION`**
   - *Direplikasi*: Ekstensi lengan bergantian ke depan setinggi dada sesuai ketukan ritmis audio.
   - *Hilang*: Tidak ada deteksi kepalan tangan (*fist*), tidak ada evaluasi vektor arah pukulan (tangan yang sekadar diam di koordinat asteroid tetap menghasilkan *Light Hit*!), dan tidak ada aktivasi rotasi panggul/kaki.

#### e) Tabel Kriteria Keberhasilan Per Level (`M01`)

| Level Kesulitan | Faktor $k$ | Radius $r_t$ | Radius $r_h$ | Tempo BPM | Umur Target ($T_{\text{life}}$) | Ambang Kecepatan $v_{\text{solid}}$ | Kondisi Gagal (*Miss*) | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`Gentle`** | `0.60` | `0.12 m` | `0.04 m` | `50–70` | `3 beats` (`3.600 s` @ 50 BPM) | $\ge 0.30\text{ m/s}$ ($+25\text{ pts}$); $<0.30$ sah *light* | Asteroid melewati $z \le 0.20\text{ m}$ atau $t_{\text{elapsed}} \ge 3.60\text{ s}$ | [gentle.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/gentle.tres), [m01_mechanic.gd:57-58](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd#L57-L58) |
| **`Standard`** | `0.75` | `0.10 m` | `0.04 m` | `60–80` | `2 beats` (`2.000 s` @ 60 BPM) | $\ge 0.30\text{ m/s}$ ($+25\text{ pts}$); $<0.30$ sah *light* | $z \le 0.20\text{ m}$ atau $t_{\text{elapsed}} \ge 2.00\text{ s}$ | [standard.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/standard.tres), [m01_mechanic.gd:57-58](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd#L57-L58) |
| **`Active`** | `0.85` | `0.08 m` | `0.04 m` | `70–90` | `2 beats` (`1.714 s` @ 70 BPM) | $\ge 0.30\text{ m/s}$ ($+25\text{ pts}$); $<0.30$ sah *light* | $z \le 0.20\text{ m}$ atau $t_{\text{elapsed}} \ge 1.714\text{ s}$ | [active.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/active.tres), [m01_mechanic.gd:57-58](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m01_asteroid_brawler/m01_mechanic.gd#L57-L58) |

#### f) Pipeline Pemrosesan Input Langkah-demi-Langkah & Perhitungan Numerik (`M01`)
1. **Data Mentah**: `left_controller.global_position` dan `right_controller.global_position` $\in \mathbb{R}^3$ (meter) dari OpenXR.
2. **Transformasi Koordinat ke `BodyFrame`**:
   $$\vec{P}_{\text{local}}(t) = R_y(-\psi_{\text{body}}) \cdot \big(\text{SpecSpace}(\vec{P}_{\text{world}}(t)) - \vec{O}_{\text{body}}\big)$$
   Titik temu benturan asteroid:
   $$z_{\text{hit}} = \text{clamp}(k, 0.10, 0.85) \cdot R_{f,\text{hand}}$$
   Kecepatan luncur asteroid dari $z_0 = 1.5\text{ m}$ dengan lead time $t_{\text{lead}} = 1.0\text{ s}$ ([mechanics_math.gd:16-18](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L16-L18)):
   $$v_a = \frac{z_0 - z_{\text{hit}}}{\max(0.05, t_{\text{lead}})}$$
3. **Penyaringan & Penghalusan**: Kecepatan instan $v_{\text{inst}}(t) = \frac{\|\vec{P}_{\text{local}}(t) - \vec{P}_{\text{local}}(t-\Delta t)\|}{\Delta t}$ dirata-ratakan dalam buffer 3 frame terakhir $\bar{v} = \frac{v_1 + v_2 + v_3}{3}$ ([main.gd:240-249](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L240-L249)).
4. **Logika Deteksi (*Anti-Tunnelling Segment-to-Sphere*)**:
   $$\min_{u \in [0, 1]} \left\| \big(\vec{P}_{\text{local}}(t-\Delta t) + u(\vec{P}_{\text{local}}(t) - \vec{P}_{\text{local}}(t-\Delta t))\big) - \vec{C}_{\text{target}}(t) \right\| \le r_t + r_h$$
   Klasifikasi pukulan mantap: $\text{is\_solid} = (\bar{v} \ge 0.30\text{ m/s})$.
5. **Penilaian Skor & Kombo**:
   $$T_{\text{life}} = L_{\text{beats}} \cdot \frac{60}{\text{BPM}}, \quad \tau = \text{clamp}\left(1 - \frac{t_{\text{hit}}}{T_{\text{life}}}, 0, 1\right)$$
   $$P_{\text{base}} = 100 + \lfloor 50 \cdot \tau \rfloor + (25 \text{ jika is\_solid})$$
   $$P_{\text{total}} = \left\lfloor P_{\text{base}} \cdot \left(1 + \frac{\min(\text{streak}_{\text{sebelum}}, 20)}{20}\right) \right\rfloor$$
6. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-01` & `AT-12`, Level `Standard`)**:
   - Diketahui: $R_{f,R} = 0.60\text{ m}$, $k = 0.75$, $r_t = 0.10\text{ m}$, $r_h = 0.04\text{ m}$, $\text{BPM} = 60$, $L_{\text{beats}} = 2$, $\text{streak}_{\text{sebelum}} = 4$.
   - $z_{\text{hit}} = 0.75 \times 0.60 = 0.45\text{ m}$.
   - $v_a = \frac{1.50 - 0.45}{1.0} = 1.05\text{ m/s}$.
   - $T_{\text{life}} = 2 \times \frac{60}{60} = 2.00\text{ s}$.
   - Tangan memukul pada $t_{\text{hit}} = 0.80\text{ s}$ dengan kecepatan $\bar{v} = 0.42\text{ m/s}$ ($\ge 0.30 \implies \text{is\_solid} = \text{true}$) dan jarak terdekat segmen ke pusat asteroid $0.11\text{ m} \le 0.14\text{ m} \implies$ **HIT**.
   - $\tau = 1 - \frac{0.80}{2.00} = 0.60 \implies P_{\text{base}} = 100 + \lfloor 50 \times 0.60 \rfloor + 25 = 155\text{ poin}$.
   - Multiplier kombo: $M = 1 + \frac{\min(4, 20)}{20} = 1.20$.
   - Poin akhir: $P_{\text{total}} = \lfloor 155 \times 1.20 \rfloor = \mathbf{186\text{ poin}}$.

#### g) Kasus Batas (*Edge Cases*)
- **Kehilangan Pelacakan (*Tracking Loss*)**: Jika tangan berada di luar kamera headset, posisi membeku. Jika tangan membeku pada jalur $x = \pm 0.10\text{ m}$, asteroid yang meluncur akan menabrak tangan diam tersebut dan memberikan skor *Light Hit* ($\bar{v} < 0.30$).
- **Kecurangan (*Cheating*)**: Pemain dapat menahan kedua tangan diam di $(x = \pm 0.10, y = 0, z = z_{\text{hit}})$ tanpa memukul, dan setiap asteroid tetap pecah menghasilkan skor dasar $100\text{–}150\text{ poin}$.
- **Asimetri Tubuh**: Kalibrasi mandiri mengukur $R_{f,L}$ dan $R_{f,R}$ secara terpisah, sehingga kecepatan asteroid $v_a$ dihitung proporsional per sisi agar tetap tiba tepat pada ketukan ke-1.0 detik.

---

### 2. `M02` — Overhead Reach ("Fruit Harvester")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M02FruitHarvester` ([m02_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m02_fruit_harvester/m02_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M02_FRUIT_HARVESTER`, judul UI: `"M02: Fruit Harvester (Overhead Reach)"` ([enums.gd:91](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L91)).
- **Di Markdown**: *M02 — Overhead Reach ("Fruit Harvester")* ([04-m02-fruit-harvester.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/04-m02-fruit-harvester.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Diagonal Shoulder Flexion Reach* (mengangkat lengan ke depan-atas diagonal seperti memetik buah dari dahan).
- **Bentuk Berdiri Penuh**: Fleksi bahu $120^\circ\text{–}170^\circ$, rotasi ke atas tulang belikat (*upward scapular rotation*), dan ekstensi ringan tulang belakang toraks.
- **Otot Target**: *Deltoideus anterior & medial*, *supraspinatus*, *trapezius pars ascendens & descendens*, dan *serratus anterior*.
- **Tempo & Efektivitas**: Gerakan lambat dan terkendali memelihara kapsul sendi glenohumeral serta meregangkan rongga dada dari postur bungkuk (*kyphosis*) pekerja meja.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Membaca posisi 3D tangan kiri dan kanan (`curr_left_local_spec`, `curr_right_local_spec`) di [m02_mechanic.gd:42-54](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m02_fruit_harvester/m02_mechanic.gd#L42-L54).
  - **Peringatan Input di Luar Desain Duduk**: Membaca `HEAD_POSITION` untuk `LeanMonitor` lateral.
- **API & Ruang Koordinat**: `XRController3D` $\to$ `BodyFrame` (`SpecSpace`). Tidak memeriksa gestur jari mencubit/menggenggam (`HAND_POSE`); sentuhan bola ujung tangan langsung memetik buah.
- **Gerakan Diterima vs Ditolak**: Tangan harus menyentuh buah saat buah turun di dalam rentang $\pm 0.25\text{ m}$ dari titik target tangkap $y_{\text{catch}}$.

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli (`EXTERNAL_KNOWLEDGE`)**: Meraih vertikal penuh lurus di atas kepala ($90^\circ\text{–}180^\circ$).
2. **Kendala Posisi Duduk**: Menengadah vertikal penuh saat memakai headset seberat $\sim 500\text{ gram}$ memicu kompresi servikal leher (*cervical hyperextension*), dan elevasi lengan $90^\circ$ murni ke atas memicu *subacromial impingement* pada bahu kaku (`STATED_IN_SOURCE`: [04-m02-fruit-harvester.md:25](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/04-m02-fruit-harvester.md#L25)).
3. **Proksi di Dalam Game**: Buah dimunculkan secara **diagonal ke depan-atas bahu** pada sudut elevasi $\phi \in \{35^\circ, 45^\circ, 55^\circ\}$. Algoritma otomatis membatasi sudut elevasi pandangan mata agar tidak pernah melebihi $45^\circ$ dari ketinggian mata $y_{\text{eye}} = 0.25\text{ m}$ ([mechanics_math.gd:49-57](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L49-L57)).
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**:
   - Sudut elevasi bahu $\phi$: `35.0°` (`Gentle`) $\to$ `45.0°` (`Standard`) $\to$ `55.0°` (`Active`) (`VERIFIED_IN_CODE`: [difficulty_preset.gd:31-53](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/difficulty_preset.gd#L31-L53)).
   - Jangkauan $k$: `0.60` $\to$ `0.75` $\to$ `0.85`; radius target: `0.12 m` $\to$ `0.10 m` $\to$ `0.08 m`.
   - **Alasan (`STATED_IN_SOURCE`)**: Draf [04-m02-fruit-harvester.md:35](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/04-m02-fruit-harvester.md#L35) menyatakan peningkatan sudut bertahap memulihkan mobilitas bahu secara aman di bawah pagar pengaman sudut pandang $\le 45^\circ$.
5. **Jejak Asal-Usul Ide**: `STATED_IN_SOURCE`: Diusulkan pada analisis survei [01-survey-analysis.md:59](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/01-survey-analysis.md#L59) untuk menjawab keluhan bahu kaku dari responden R2, R3, dan R4.
6. **Vonis Fidelitas**: **`FAITHFUL`** — Sangat setia mereplikasi peregangan fleksi diagonal bahu depan-atas duduk, meskipun pemain tidak perlu menurunkan tangan untuk menaruh buah ke keranjang.

#### e) Tabel Kriteria Keberhasilan Per Level (`M02`)

| Level | Faktor $k$ | Sudut Elevasi Bahu $\phi$ | Radius $r_t$ | Kecepatan Jatuh $v_f$ | Jendela Tangkap ($\Delta y$ / Durasi) | Bonus Buah Emas | Kondisi Gagal (*Miss*) | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`Gentle`** | `0.60` | `35.0°` | `0.12 m` | `0.40 m/s` | `±0.25 m` (`1.250 s`) | $+50\text{ pts}$ (tiap kelipatan 4) | $y_{\text{curr}} < y_{\text{catch}} - 0.25\text{ m}$ | [gentle.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/gentle.tres), [m02_mechanic.gd:56-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m02_fruit_harvester/m02_mechanic.gd#L56-L84) |
| **`Standard`** | `0.75` | `45.0°` | `0.10 m` | `0.40 m/s` | `±0.25 m` (`1.250 s`) | $+50\text{ pts}$ (tiap kelipatan 4) | $y_{\text{curr}} < y_{\text{catch}} - 0.25\text{ m}$ | [standard.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/standard.tres), [m02_mechanic.gd:56-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m02_fruit_harvester/m02_mechanic.gd#L56-L84) |
| **`Active`** | `0.85` | `55.0°` | `0.08 m` | `0.40 m/s` | `±0.25 m` (`1.250 s`) | $+50\text{ pts}$ (tiap kelipatan 4) | $y_{\text{curr}} < y_{\text{catch}} - 0.25\text{ m}$ | [active.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/active.tres), [m02_mechanic.gd:56-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m02_fruit_harvester/m02_mechanic.gd#L56-L84) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M02`)
1. **Penentuan Titik Muncul Buah**:
   Jari-jari jangkauan bahu: $r = k \cdot L_{\text{arm}}$.
   Dari koordinat bahu $\vec{S} = (\pm 0.20, 0.12, 0.0)\text{ m}$ dan tinggi mata $y_{\text{eye}} = 0.25\text{ m}$:
   $$y = S_y + r \sin\phi, \quad z = S_z + r \cos\phi, \quad \theta_{\text{gaze}} = \text{rad\_to\_deg}\left(\text{atan2}(y - y_{\text{eye}}, z)\right)$$
   Jika $\theta_{\text{gaze}} > 45^\circ$, turunkan $\phi$ sebesar $1^\circ$ bertahap hingga $\theta_{\text{gaze}} \le 45^\circ$.
2. **Lintasan Turun Buah**:
   $$y(t) = (y_{\text{catch}} + 0.25) - 0.40 \cdot t$$
3. **Deteksi Benturan Segmen**: Fungsi `ZenoGeometry.check_valid_hand_hit()` dengan batas $r_t + 0.04\text{ m}$.
4. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-03`, Level `Active`)**:
   - Diketahui: $L_{\text{arm}} = 0.60\text{ m}$, $k = 0.85$, $\phi = 55^\circ$, bahu kanan $\vec{S}_R = (0.20, 0.12, 0.0)\text{ m}$.
   - $r = 0.85 \times 0.60 = 0.51\text{ m}$.
   - $y = 0.12 + 0.51 \sin(55^\circ) = 0.12 + 0.41776 = 0.5378\text{ m}$.
   - $z = 0.0 + 0.51 \cos(55^\circ) = 0.29252\text{ m}$.
   - Sudut pandang mata: $\theta_{\text{gaze}} = \text{atan2}(0.5378 - 0.25, 0.29252) = \text{atan2}(0.2878, 0.29252) = \mathbf{44.536^\circ} \le 45^\circ \implies$ **VALID tanpa penurunan $\phi$**.
   - Buah emas (`_spawn_count = 4`) dipetik pada $t_{\text{hit}} = 0.50\text{ s}$ dari durasi $1.25\text{ s}$ dengan $\text{streak}_{\text{sebelum}} = 0$:
     $\tau = 1 - \frac{0.50}{1.25} = 0.60 \implies P_{\text{total}} = 100 + \lfloor 50 \times 0.60 \rfloor + 50 = \mathbf{180\text{ poin}}$.

#### g) Kasus Batas (*Edge Cases*)
- **Menahan Tangan Statis di Atas**: Karena buah selalu jatuh melewati koordinat $(x = \pm 0.20, y_{\text{catch}}, z_{\text{catch}})$, pemain yang menahan tangan terus di atas kepala akan otomatis memetik buah begitu buah menyentuh tangan tanpa perlu melakukan gerakan memetik berulang.

---

### 3. `M03` — Side Arm Raise ("Glider Pilot")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M03GliderPilot` ([m03_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M03_GLIDER_PILOT`, judul UI: `"M03: Glider Pilot (Side Arm Raise)"` ([enums.gd:92](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L92)).
- **Di Markdown**: *M03 — Side Arm Raise ("Glider Pilot")* ([05-m03-glider-pilot.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/05-m03-glider-pilot.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Lateral Shoulder Abduction* (mengangkat kedua lengan lurus ke samping menjauhi tubuh hingga setinggi bahu).
- **Otot Target**: *Deltoideus pars acromialis* (bahu samping), *supraspinatus*, dan *trapezius* atas/bawah.
- **Tempo & Efektivitas**: Gerakan abduksi isometrik dan eksentrik lambat menguatkan manset pemutar bahu (*rotator cuff*) dan mencegah atrofi deltoid lateral.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Membaca posisi lateral dan vertikal tangan kiri dan kanan (`curr_left_local_spec` dan `curr_right_local_spec`) di [m03_mechanic.gd:37](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L37).
  - Kamera headset $100\%$ diam (translasi/rotasi kamera tidak mengemudikan pesawat untuk mencegah *cybersickness*).

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli (`EXTERNAL_KNOWLEDGE`)**: Abduksi bahu lateral bilateral hingga $90^\circ$ di bidang frontal.
2. **Kendala Posisi Duduk**: Pemain di kursi roda atau sofa memiliki roda/sandaran tangan di samping paha ($x \approx \pm 0.25\text{ m}$); mengangkat tangan terlalu lebar sambil memiringkan badan berisiko membuat kursi roda terjungkal; memiringkan kamera visual VR memicu mabuk gerak berat ($r = -0.817$, Flatlandsmo 2023).
3. **Proksi di Dalam Game**: Minigame kendali pesawat luncur (*Glider Pilot*). Kamera dunia diikat kaku; cincin datang mendekat pada kecepatan $1.2\text{ m/s}$; pergeseran horizontal pesawat dikendalikan oleh selisih tinggi tangan kanan dan kiri: $\text{roll} = \text{atan2}(y_R - y_L, x_R - x_L)$ ([mechanics_math.gd:92-95](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L92-L95)).
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**:
   - Nilai `preset.m03_abduction_theta_deg`: `60.0°` (`Gentle`) $\to$ `75.0°` (`Standard`) $\to$ `90.0°` (`Active`).
   - **KONTRADIKSI / CACAT IMPLEMENTASI (`CONTRADICTION`)**: Di dalam runtime [m03_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd), parameter `m03_abduction_theta_deg` **sama sekali tidak pernah dibaca**! Kecepatan cincin ($1.2\text{ m/s}$), toleransi cincin ($0.22\text{ m}$), dan gain kemudi ($0.10$) identik di ketiga level!
5. **Jejak Asal-Usul Ide**: `STATED_IN_SOURCE`: Berasal dari gerakan #3 *Side Arm Raise* di [Proposal-Unfixed.md:170](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L170), diimplementasikan sebagai target samping di Unity `Ex03`, lalu diubah menjadi kokpit glider di Godot untuk menghilangkan kebutuhan target visual samping yang memaksa tolehan tajam.
6. **Vonis Fidelitas**: **`ABSTRACTED`**
   - *Alasan*: Karena fungsi `MechanicsMath.m03_compute_wing_target_offset()` tidak dipanggil untuk memeriksa apakah kedua lengan terentang ke samping pada sudut $\theta \pm 15^\circ$, pemain dapat menaruh kedua tangan berdekatan di depan perut ($\Delta x = 0.10\text{ m}$) dan cukup menggoyangkan satu tangan naik-turun $2\text{ cm}$ untuk menghasilkan sudut kemudi besar dan memenangkan ronde tanpa melakukan *Side Arm Raise* sama sekali!

#### e) Tabel Kriteria Keberhasilan Per Level (`M03`)

| Level | Sudut Abduksi Teoretis | Kecepatan Luncur Cincin | Posisi Cincin $x_{\text{ring}}$ | Toleransi Lateral Pesawat | Bonus Sayap Pasif | Kondisi Gagal (*Miss*) | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`Gentle`** | `60.0°` *(diabaikan di runtime)* | `1.20 m/s` (dari $z=1.8$ ke $0.45\text{ m}$ dalam $1.125\text{ s}$) | $\{-0.35, 0.35, 0.0, -0.45, 0.45\}\text{ m}$ | $|x_{\text{glider}} - x_{\text{ring}}| \le 0.22\text{ m}$ | $+10\text{ pts/s}$ tanpa syarat | $|x_{\text{glider}} - x_{\text{ring}}| > 0.22\text{ m}$ saat $z \le 0.45\text{ m}$ | [m03_mechanic.gd:37-78](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L37-L78) |
| **`Standard`** | `75.0°` *(diabaikan di runtime)* | `1.20 m/s` | Sama | $|x_{\text{glider}} - x_{\text{ring}}| \le 0.22\text{ m}$ | $+10\text{ pts/s}$ tanpa syarat | Sama | [m03_mechanic.gd:37-78](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L37-L78) |
| **`Active`** | `90.0°` *(diabaikan di runtime)* | `1.20 m/s` | Sama | $|x_{\text{glider}} - x_{\text{ring}}| \le 0.22\text{ m}$ | $+10\text{ pts/s}$ tanpa syarat | Sama | [m03_mechanic.gd:37-78](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L37-L78) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M03`)
1. **Perhitungan Roll Kemudi & Kecepatan Lateral**:
   $$\Delta x = \max(0.05, x_R - x_L), \quad \Delta y = y_R - y_L$$
   $$\text{roll}_{\text{deg}} = \frac{180}{\pi} \cdot \text{atan2}(\Delta y, \Delta x), \quad v_{\text{lat}} = 0.10 \cdot \text{roll}_{\text{deg}}\text{ (m/s)}$$
   $$x_{\text{glider}}(t + \Delta t) = \text{clamp}\big(x_{\text{glider}}(t) + v_{\text{lat}} \cdot \Delta t, -0.60, +0.60\big)$$
2. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-02`)**:
   - Posisi tangan kiri $\vec{P}_L = (-0.50, 0.00, 0.30)\text{ m}$, tangan kanan $\vec{P}_R = (0.50, 0.10, 0.30)\text{ m}$.
   - $\Delta x = 0.50 - (-0.50) = 1.00\text{ m}$, $\Delta y = 0.10 - 0.00 = +0.10\text{ m}$.
   - $\text{roll}_{\text{deg}} = \text{rad\_to\_deg}(\text{atan2}(0.10, 1.00)) = \mathbf{5.7106^\circ}$.
   - $v_{\text{lat}} = 0.10 \times 5.7106 = \mathbf{0.5711\text{ m/s}}$.
   - Dalam waktu $0.613\text{ s}$, glider berpindah sejauh $0.35\text{ m}$ menuju cincin pertama di $x_{\text{ring}} = +0.35\text{ m}$.
   - Karena $|0.35 - 0.35| = 0.00 \le 0.22\text{ m} \implies$ **HIT (Cincin tembus, skor kombo diberikan)**.

#### g) Kasus Batas (*Edge Cases*)
- **Mode Satu Tangan (`HandMode.LEFT_ONLY` / `RIGHT_ONLY`)**: Fungsi `m03_compute_steering` selalu menghitung `curr_right - curr_left`. Jika pengguna hanya memiliki satu tangan aktif (tangan lain diam di pangkuan $y = -0.45\text{ m}$), glider akan mengalami defleksi kemudi ekstrem terus-menerus dan macet di dinding pembatas $x = \pm 0.60\text{ m}$.

---

### 4. `M04` — Trunk Twist ("Turret Gunner")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M04TurretGunner` ([m04_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M04_TURRET_GUNNER`, judul UI: `"M04: Turret Gunner (Trunk Twist)"` ([enums.gd:93](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L93)), Safety Level: `LEVEL_B`.
- **Di Markdown**: *M04 — Trunk Twist ("Turret Gunner")* ([06-m04-turret-gunner.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/06-m04-turret-gunner.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Russian Twist / Thoracic Axial Rotation* (memutar sangkar rusuk dan tulang dada ke kiri dan kanan sambil mengunci panggul di kursi).
- **Otot Target**: *Obliquus externus & internus abdominis*, *rotatores thoracis*, *multifidus*, dan *transversus abdominis*.
- **Tempo & Efektivitas**: Memobilisasi tulang belakang toraks yang kaku akibat berjam-jam duduk statis menghadap monitor komputer.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Membaca posisi kedua tangan (`curr_left_local_spec`, `curr_right_local_spec`) di [m04_mechanic.gd:34-38](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L34-L38).
  - **Catatan Proksi**: Karena perangkat VR konsumen tidak memiliki pelacak dada (*chest/sternum tracker*), game menghitung titik tengah kedua tangan $\vec{M} = \frac{\vec{P}_L + \vec{P}_R}{2}$ yang didekap di dekat dada sebagai proksi arah hadap orientasi torso pemain!

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli (`EXTERNAL_KNOWLEDGE`)**: Rotasi aksial kolom spinal dengan panggul terkunci di kursi.
2. **Kendala Posisi Duduk**: Pemain di kursi kantor berputar (*swivel chair*) berisiko memutar seluruh kursinya secara pasif alih-alih meregangkan otot oblik; jika kursi beroda tergelincir, pemain bisa jatuh (`STATED_IN_SOURCE`: [06-m04-turret-gunner.md:47-50](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/06-m04-turret-gunner.md#L47-L50)).
3. **Proksi di Dalam Game**:
   - Game mengkategorikan mekanik ini sebagai `LEVEL_B` dan memunculkan pop-up konfirmasi kursi stabil (`PauseReason.STABLE_CHAIR_CONFIRMATION` di [game_flow.gd:167-171](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/autoload/game_flow.gd#L167-L171)). Jika ditolak, game otomatis menggantinya dengan mekanik Level A (`AT-28`).
   - Sudut hadap dada dihitung dari $\psi_{\text{aim}} = \text{atan2}(M_x, M_z)$ dengan syarat jarak tangan ke dada $\|\vec{M}\| \le 0.45\text{ m}$.
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**:
   - Sudut bidik target $\psi_t = \pm \min(k \cdot \psi_{\text{max,side}}, 60^\circ)$ membesar seiring faktor $k \in \{0.60, 0.75, 0.85\}$.
5. **Jejak Asal-Usul Ide**: `STATED_IN_SOURCE`: Ditambahkan pasca-survei [01-survey-analysis.md:44-47](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/01-survey-analysis.md#L44-L47) atas permintaan responden R1, R3, dan R4 yang mengeluhkan punggung bawah kaku.
6. **Vonis Fidelitas**: **`APPROXIMATION`**
   - *Alasan*: Syarat $\|\vec{M}\| \le 0.45\text{ m}$ mencegah tangan direntangkan penuh, namun karena batas $0.45\text{ m}$ relatif longgar, pemain masih bisa menggeser kedua tangan ke kiri/kanan sejauh $20\text{ cm}$ di depan dada untuk memanipulasi sudut tanpa benar-benar memutar tulang belakang toraks.

#### e) Tabel Kriteria Keberhasilan Per Level (`M04`)

| Level | Faktor $k$ | Sudut Target $\psi_t$ (Default $\psi_{L}=50^\circ, \psi_{R}=40^\circ$) | Syarat Jarak Dada $\|\vec{M}\|$ | Toleransi Sudut | Durasi Kunci (*Lock Time*) | Kondisi Gagal / Decay | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`Gentle`** | `0.60` | Kiri: `-30.0°`, Kanan: `+24.0°` | $\le 0.45\text{ m}$ | $\pm 6.0^\circ$ | `0.30 s` | Jika di luar toleransi, timer kunci berkurang $0.5 \times \Delta t$ | [m04_mechanic.gd:34-61](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L34-L61), [mechanics_math.gd:104-129](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L104-L129) |
| **`Standard`** | `0.75` | Kiri: `-37.5°`, Kanan: `+30.0°` | $\le 0.45\text{ m}$ | $\pm 6.0^\circ$ | `0.30 s` | Timer kunci berkurang $0.5 \times \Delta t$ | [m04_mechanic.gd:34-61](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L34-L61) |
| **`Active`** | `0.85` | Kiri: `-42.5°`, Kanan: `+34.0°` | $\le 0.45\text{ m}$ | $\pm 6.0^\circ$ | `0.30 s` | Timer kunci berkurang $0.5 \times \Delta t$ | [m04_mechanic.gd:34-61](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L34-L61) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M04`)
1. **Titik Tengah & Sudut Yaw Tangan**:
   $$\vec{M} = \frac{\vec{P}_L + \vec{P}_R}{2}, \quad \psi_{\text{aim}} = \text{rad\_to\_deg}\big(\text{atan2}(M_x, \max(0.001, M_z))\big)$$
2. **Kondisi Penguncian Target**:
   $$\|\vec{M}\| \le 0.45\text{ m} \quad \land \quad |\psi_{\text{aim}} - \psi_t| \le 6.0^\circ \quad \text{selama } T_{\text{lock}} = 0.30\text{ s}$$
3. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-19`, Level `Active`)**:
   - Target kiri: $\psi_{\text{max},L} = 50^\circ, k = 0.85 \implies \psi_t = -1.0 \times \min(0.85 \times 50^\circ, 60^\circ) = \mathbf{-42.5^\circ}$.
   - Pemain memutar dada ke kiri hingga $\vec{P}_L = (-0.24, 0.0, 0.22)\text{ m}$ dan $\vec{P}_R = (-0.16, 0.0, 0.26)\text{ m}$.
   - $\vec{M} = (-0.20, 0.0, 0.24)\text{ m} \implies \|\vec{M}\| = \sqrt{(-0.20)^2 + 0.24^2} = 0.3124\text{ m} \le 0.45\text{ m}$ (**VALID**).
   - $\psi_{\text{aim}} = \text{rad\_to\_deg}(\text{atan2}(-0.20, 0.24)) = -39.805^\circ$.
   - Selisih sudut: $|-39.805^\circ - (-42.5^\circ)| = 2.695^\circ \le 6.0^\circ$ (**TERKUNCI**).
   - Setelah ditahan $0.30\text{ s}$, target meledak dan skor $135\text{ poin}$ diberikan.

#### g) Kasus Batas (*Edge Cases*)
- **Translasi Lengan Tanpa Memutar Torso**: Menggeser kedua tangan secara paralel ke samping kiri/kanan sejauh $18\text{ cm}$ di depan dada menghasilkan sudut bidik $\sim 36^\circ$ yang meloloskan validasi tanpa keterlibatan otot oblik tulang belakang.

---

### 5. `M05` — Seated Row ("Cosmic Tug-of-War")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M05CosmicTugOfWar` ([m05_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M05_COSMIC_TUG_OF_WAR`, judul UI: `"M05: Cosmic Tug-of-War (Seated Row)"` ([enums.gd:94](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L94)), Safety Level: `LEVEL_A`.
- **Di Markdown**: *M05 — Seated Row ("Cosmic Tug-of-War")* ([07-m05-cosmic-tug-of-war.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/07-m05-cosmic-tug-of-war.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Cable Row / Resistance Band Row* (menarik beban kabel dari depan dada ke arah pinggang sambil melakukan retraksi skapula).
- **Otot Target**: *Latissimus dorsi*, *rhomboideus major & minor*, *trapezius pars transversa*, dan *biceps brachii*.
- **Tempo & Efektivitas**: Melatih otot punggung atas untuk melawan postur bahu membungkuk ke depan (*protracted rounded shoulders*).

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Komponen kedalaman $Z$ tangan (`curr_left_local_spec.z` atau `curr_right_local_spec.z`) di [m05_mechanic.gd:33-47](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L33-L47).
  - Kecepatan tangan dihitung untuk memicu peringatan jika gerakan terlalu menyentak ($v > 1.5\text{ m/s}$).
  - **KONTRADIKSI IMPLEMENTASI (`CONTRADICTION`)**:
    - Baris 33 memanggil `pick_hand_for_spawn(0)`. Karena indeks konstan `0`, pada mode `BOTH_HANDS` fungsi **selalu mengembalikan tangan kiri** (`0 % 2 == 0`). Akibatnya, pada mode dua tangan, kode hanya memeriksa tangan kiri!
    - Draf Markdown ([07-m05-cosmic-tug-of-war.md:23](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/07-m05-cosmic-tug-of-war.md#L23)) menyebutkan *"Grab the handle (hold grip)"*, tetapi di kode tidak ada pembacaan tombol grip maupun gestur `HAND_POSE`.

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli (`EXTERNAL_KNOWLEDGE`)**: Gerakan mendayung dengan beban tarikan mekanis nyata.
2. **Kendala Posisi Duduk**: Headset VR mandiri tidak memiliki beban fisik (*tensile resistance*). Dokumen awal Naufy secara eksplisit mencatat: *"Untuk latihan kekuatan yang sebenarnya, diperlukan resistansi tambahan yang sesuai"* (`STATED_IN_SOURCE`: [Proposal-Unfixed.md:191](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L191)).
3. **Proksi di Dalam Game**: Proksi *pseudo-weight*. Menarik puing luar angkasa seberat simulasi dari jarak $1.0\text{ m}$ dengan gain proporsional $g = \min\left(1.0, \frac{1.0}{N \cdot S}\right)$ di mana $N = 7$ kayuhan, sehingga setiap kayuhan $S = z_{\text{start}} - 0.15\text{ m}$ hanya menggeser puing sejauh $\approx 0.1429\text{ m}$ ([mechanics_math.gd:134-152](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L134-L152)).
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**:
   - Jarak awal kayuhan $z_{\text{start}} = k \cdot R_{f,\text{hand}}$ bertambah jauh seiring $k \in \{0.60, 0.75, 0.85\}$, memperpanjang jarak kayuhan $S$.
5. **Jejak Asal-Usul Ide**: `STATED_IN_SOURCE`: Gerakan #10 *Seated Row* di [Proposal-Unfixed.md:190-191](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L190-L191).
6. **Vonis Fidelitas**: **`APPROXIMATION`**
   - *Alasan*: Berhasil memandu jangkauan retraksi skapula sepanjang sumbu $Z$, tetapi kehilangan sensasi beban mekanis fisik dan cacat koordinasi dua tangan akibat bug `pick_hand_for_spawn(0)`.

#### e) Tabel Kriteria Keberhasilan Per Level (`M05`)

| Level | Faktor $k$ | Titik Mulai $z_{\text{start}}$ ($R_f = 0.60\text{ m}$) | Titik Selesai $z_{\text{end}}$ | Jarak Kayuhan $S$ | Gain $g$ & Progres/Kayuhan | Bonus Tuntas ($1.0\text{ m}$) | Cue Kecepatan | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`Gentle`** | `0.60` | `0.360 m` (ambang $\ge 0.300\text{ m}$) | `0.150 m` (ambang $\le 0.210\text{ m}$) | `0.210 m` | $g = 0.6803$; `0.1429 m/kayuhan` | $+100\text{ pts}$ | Peringatan jika $v > 1.5\text{ m/s}$ | [m05_mechanic.gd:35-61](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L35-L61) |
| **`Standard`** | `0.75` | `0.450 m` (ambang $\ge 0.390\text{ m}$) | `0.150 m` (ambang $\le 0.210\text{ m}$) | `0.300 m` | $g = 0.4762$; `0.1429 m/kayuhan` | $+100\text{ pts}$ | Peringatan jika $v > 1.5\text{ m/s}$ | [m05_mechanic.gd:35-61](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L35-L61) |
| **`Active`** | `0.85` | `0.510 m` (ambang $\ge 0.450\text{ m}$) | `0.150 m` (ambang $\le 0.210\text{ m}$) | `0.360 m` | $g = 0.3968$; `0.1429 m/kayuhan` | $+100\text{ pts}$ | Peringatan jika $v > 1.5\text{ m/s}$ | [m05_mechanic.gd:35-61](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L35-L61) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M05`)
1. **Perhitungan Parameter**:
   $$z_{\text{start}} = k \cdot R_{f}, \quad S = \max(0.02, z_{\text{start}} - 0.15), \quad g = \min\left(1.0, \frac{1.0}{7 \cdot S}\right), \quad \Delta D = g \cdot S$$
2. **Mesin Keadaan 2-Langkah**:
   - *Langkah 1 (Ambil Tali)*: `if not _stroke_started and hand_z >= z_start - 0.06` $\implies$ `_stroke_started = true`.
   - *Langkah 2 (Tarik Pinggang)*: `if _stroke_started and hand_z <= 0.15 + 0.06` $\implies$ Kurangi jarak puing sebesar $\Delta D$ dan catat hit.
3. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-20`, Level `Standard`)**:
   - $R_f = 0.60\text{ m}, k = 0.75 \implies z_{\text{start}} = 0.45\text{ m}$, $S = 0.45 - 0.15 = 0.30\text{ m}$.
   - $g = \frac{1.0}{7 \times 0.30} = \mathbf{0.47619}$, $\Delta D = 0.47619 \times 0.30 = \mathbf{0.14286\text{ m}}$.
   - Pemain mengulurkan tangan kiri ke $z = 0.40\text{ m} \ge 0.39\text{ m} \implies$ Tali terambil (`_stroke_started = true`).
   - Pemain menarik tangan kiri ke $z = 0.19\text{ m} \le 0.21\text{ m} \implies$ 1 kayuhan selesai! Sisa puing $1.0 - 0.14286 = 0.8571\text{ m}$.

#### g) Kasus Batas (*Edge Cases*)
- **Jarak Kayuhan Terlalu Pendek pada Jangkauan Kecil**: Jika pengguna memiliki jangkauan pendek ($R_f = 0.35\text{ m}$) pada level `Gentle` ($k=0.60$), maka $z_{\text{start}} = 0.21\text{ m}$. Ambang ambil ($0.21 - 0.06 = 0.15\text{ m}$) berhimpitan dengan ambang selesai ($0.15 + 0.06 = 0.21\text{ m}$), sehingga pemain dapat memicu hit setiap frame hanya dengan menahan tangan bergetar di $z = 0.18\text{ m}$.

---

### 6. `M06` — Forward Press ("Force Blast")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M06ForceBlast` ([m06_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m06_force_blast/m06_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M06_FORCE_BLAST`, judul UI: `"M06: Force Blast (Forward Press)"` ([enums.gd:95](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L95)).
- **Di Markdown**: *M06 — Forward Press ("Force Blast")* ([08-m06-force-blast.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/08-m06-force-blast.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Chest Press / Isometric Wall Push* (mendorong kedua tangan lurus ke depan melawan beban isometrik).
- **Otot Target**: *Pectoralis major*, *deltoideus anterior*, dan *triceps brachii*.
- **Tempo & Efektivitas**: Kontraksi isometrik selama $\ge 2.0\text{ detik}$ merekrut unit motorik serat otot tipe I dan II tanpa membutuhkan beban barbel fisik.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Komponen $Z$ kedalaman tangan (`curr_left_local_spec.z` dan `curr_right_local_spec.z`) di [m06_mechanic.gd:45-58](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m06_force_blast/m06_mechanic.gd#L45-L58).
  - Tidak memvalidasi posisi $(X, Y)$ tangan terhadap luas bidang dorong.

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli (`EXTERNAL_KNOWLEDGE`)**: Menekan beban resistansi ke depan dada secara simultan.
2. **Kendala Posisi Duduk**: Tanpa beban mekanis fisik, dorongan cepat biasa akan menjadi identik dengan *Seated Boxing*. Jika panjang jangkauan tangan kiri dan kanan berbeda (asimetris), bidang dorong tidak boleh memaksa tangan yang lebih pendek over-ekstensi.
3. **Proksi di Dalam Game**:
   - Menempatkan bidang dorong pada jangkauan minimum kedua tangan: $z_{\text{plane}} = k \cdot \min(R_{f,L}, R_{f,R})$ (`AT-21`, [mechanics_math.gd:157-165](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L157-L165)).
   - Membebankan tahanan isometrik waktu pengisian energi (*isometric charge hold*) selama $T_{\text{full}} = 2.0\text{ s}$ pada kedalaman $z \ge z_{\text{plane}} + 0.03\text{ m}$.
   - Memberikan bonus sinkronisasi $+25\text{ poin}$ jika $|z_L - z_R| \le 0.05\text{ m}$.
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**: Jarak bidang $z_{\text{plane}}$ bertambah seiring $k \in \{0.60, 0.75, 0.85\}$.
5. **Jejak Asal-Usul Ide**: `STATED_IN_SOURCE`: Gerakan #9 *Forward Press* di [Proposal-Unfixed.md:188-189](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L188-L189).
6. **Vonis Fidelitas**: **`APPROXIMATION`** — Kontraksi isometrik $2.0\text{ s}$ berhasil mengaktifkan otot dada dan bahu depan, meskipun toleransi lateral $(X, Y)$ diabaikan.

#### e) Tabel Kriteria Keberhasilan Per Level (`M06`)

| Level | Faktor $k$ | Posisi Bidang $z_{\text{plane}}$ ($\min R_f = 0.60\text{ m}$) | Ambang Penetrasi Tekan | Waktu Tahan Penuh | Syarat Sinkronisasi 2 Tangan | Cooldown Pasca-Ledakan | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **`Gentle`** | `0.60` | `0.360 m` | $\ge 0.390\text{ m}$ ($+0.03\text{ m}$) | `2.00 s` (lepas dini $\ge 0.4\text{ s}$) | $|z_L - z_R| \le 0.05\text{ m}$ ($+25\text{ pts}$) | `1.00 s` | [m06_mechanic.gd:45-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m06_force_blast/m06_mechanic.gd#L45-L84) |
| **`Standard`** | `0.75` | `0.450 m` | $\ge 0.480\text{ m}$ | `2.00 s` (lepas dini $\ge 0.4\text{ s}$) | $|z_L - z_R| \le 0.05\text{ m}$ ($+25\text{ pts}$) | `1.00 s` | [m06_mechanic.gd:45-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m06_force_blast/m06_mechanic.gd#L45-L84) |
| **`Active`** | `0.85` | `0.510 m` | $\ge 0.540\text{ m}$ | `2.00 s` (lepas dini $\ge 0.4\text{ s}$) | $|z_L - z_R| \le 0.05\text{ m}$ ($+25\text{ pts}$) | `1.00 s` | [m06_mechanic.gd:45-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m06_force_blast/m06_mechanic.gd#L45-L84) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M06`)
1. **Posisi Bidang**:
   $$z_{\text{plane}} = k \cdot \min(R_{f,L}, R_{f,R}), \quad z_{\text{req}} = z_{\text{plane}} + 0.03\text{ m}$$
2. **Evaluasi Tekanan & Akumulasi Waktu**:
   $$\text{is\_pressing} = (z_L \ge z_{\text{req}}) \land (z_R \ge z_{\text{req}}), \quad \text{is\_synced} = (|z_L - z_R| \le 0.05\text{ m})$$
   $$\text{charge} = \text{clamp}\left(\frac{t_{\text{hold}}}{2.0}, 0, 1\right), \quad P_{\text{base}} = \text{round}(100 \cdot \text{charge}) + (25 \text{ jika is\_synced})$$
3. **Contoh Perhitungan Numerik Riil (Kasus Rani `AT-21`, Level `Standard`)**:
   - $R_{f,L} = 0.55\text{ m}$, $R_{f,R} = 0.42\text{ m}$, $k = 0.75$.
   - $z_{\text{plane}} = 0.75 \times \min(0.55, 0.42) = 0.75 \times 0.42 = \mathbf{0.315\text{ m}}$, $z_{\text{req}} = \mathbf{0.345\text{ m}}$.
   - Pemain menekan ke $z_L = 0.36\text{ m}$ dan $z_R = 0.35\text{ m}$ ($|0.36 - 0.35| = 0.01\text{ m} \le 0.05\text{ m} \implies \text{is\_synced} = \text{true}$).
   - Ditahan selama $t_{\text{hold}} = 1.50\text{ s}$ lalu ditarik mundur:
     $\text{charge} = \frac{1.50}{2.00} = 0.75 \implies P_{\text{base}} = \text{round}(100 \times 0.75) + 25 = 75 + 25 = \mathbf{100\text{ poin}}$.

#### g) Kasus Batas (*Edge Cases*)
- **Menahan Tangan Terus Menerus di Depan**: Setelah muatan dilepaskan, timer cooldown berjalan $1.0\text{ s}$. Jika pemain tetap menahan kedua tangannya di $z \ge z_{\text{req}}$ tanpa pernah menarik tangan kembali ke dada, pengisian muatan berikutnya otomatis langsung berjalan lagi begitu cooldown habis (tidak ada histeresis penarikan tangan wajib seperti di Unity `Ex04`).

---

### 7. `M07` — Arm Circles ("Shield Generator Crank")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M07ShieldCrank` ([m07_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M07_SHIELD_CRANK`, judul UI: `"M07: Shield Generator Crank (Arm Circles)"` ([enums.gd:96](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L96)).
- **Di Markdown**: *M07 — Arm Circles ("Shield Generator Crank")* ([09-m07-shield-generator-crank.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/09-m07-shield-generator-crank.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Arm Circles / Shoulder Circumduction* (memutar kedua lengan membentuk lingkaran di depan dada/bahu).
- **Otot Target**: *Supraspinatus*, *infraspinatus*, *teres minor*, *subscapularis*, dan *deltoideus*.
- **Tempo & Efektivitas**: Irama sirkular ritmis melumasi kapsul sendi bahu dengan cairan sinovial dan melatih kontrol neuromuskular bahu.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Hanya membaca posisi $(X, Y)$ dari **tangan kanan saja** (`curr_right_local_spec`) di [m07_mechanic.gd:47-55](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L47-L55). Parameter tangan kiri `_curr_left_local_spec` diberi garis bawah dan diabaikan sepenuhnya!
  - **KONTRADIKSI IMPLEMENTASI (`CONTRADICTION`)**:
    - Draf Markdown ([09-m07-shield-generator-crank.md:23](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/09-m07-shield-generator-crank.md#L23)) mewajibkan memutar kedua tangan dan berganti arah putaran (*clockwise* vs *counter-clockwise*) tiap 10 detik.
    - Di kode, tangan kiri tidak dinilai sama sekali, dan arah dihitung menggunakan nilai mutlak `absf(d_angle)` sehingga putaran searah maupun berlawanan jarum jam bernilai sama persis.

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli**: *Shoulder Rolls / Arm Circles* di draf Naufy [Proposal-Unfixed.md:166-167](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L166-L167).
2. **Kendala Posisi Duduk**: Headset VR tidak dapat mendeteksi bahu yang berputar naik-turun jika tangan diam di pangkuan.
3. **Proksi di Dalam Game**: Mengubah rotasi bahu menjadi putaran engkol tangan di bidang $(X, Y)$ pada jarak $z = 0.40\text{ m}$.
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**:
   - Jari-jari lingkaran: `0.12 m` $\to$ `0.18 m` $\to$ `0.25 m`.
   - Irama frekuensi: `0.50 Hz` (30 RPM) $\to$ `0.75 Hz` (45 RPM) $\to$ `1.00 Hz` (60 RPM).
5. **Vonis Fidelitas**: **`PARTIAL` / `APPROXIMATION`** — Validasi matematis pita jari-jari dan pita frekuensi bekerja akurat untuk tangan kanan, tetapi tangan kiri tidak diperiksa dan arah putaran tidak dibedakan.

#### e) Tabel Kriteria Keberhasilan Per Level (`M07`)

| Level | Jari-jari $r$ | Toleransi Radial | Frekuensi Target $f_t$ | Toleransi Frekuensi | Laju Energi Perisai | Bonus Penuh ($E=100$) | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **`Gentle`** | `0.12 m` | $\pm 0.06\text{ m}$ | `0.50 Hz` | $\pm 25\%$ (`[0.375, 0.625] Hz`) | $+10/\text{s}$ in-band, $-5/\text{s}$ out | $+100\text{ pts}$ | [gentle.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/gentle.tres), [m07_mechanic.gd:47-70](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L47-L70) |
| **`Standard`** | `0.18 m` | $\pm 0.06\text{ m}$ | `0.75 Hz` | $\pm 25\%$ (`[0.563, 0.938] Hz`) | $+10/\text{s}$ in-band, $-5/\text{s}$ out | $+100\text{ pts}$ | [standard.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/standard.tres), [m07_mechanic.gd:47-70](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L47-L70) |
| **`Active`** | `0.25 m` | $\pm 0.06\text{ m}$ | `1.00 Hz` | $\pm 25\%$ (`[0.750, 1.250] Hz`) | $+10/\text{s}$ in-band, $-5/\text{s}$ out | $+100\text{ pts}$ | [active.tres](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/resources/difficulty_presets/active.tres), [m07_mechanic.gd:47-70](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L47-L70) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M07`)
1. **Ekstraksi Sudut Polar & Frekuensi Sesaat**:
   $$\vec{\Delta} = \vec{P}_R - (0.22, 0.05, 0.40), \quad \theta(t) = \text{atan2}(\Delta_y, \Delta_x), \quad \Delta\theta = \text{wrapf}(\theta(t) - \theta(t-\Delta t), -\pi, \pi)$$
   $$f_{\text{ukur}} = \frac{|\Delta\theta / \Delta t|}{2\pi}, \quad \rho = \sqrt{\Delta_x^2 + \Delta_y^2}$$
2. **Validasi In-Band**:
   $$\text{on\_circle} = (|\rho - r| \le 0.06\text{ m}), \quad \text{in\_band} = \left(\frac{|f_{\text{ukur}} - f_t|}{f_t} \le 0.25\right)$$
3. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-22`, Level `Standard`)**:
   - $r = 0.18\text{ m}, f_t = 0.75\text{ Hz}$.
   - Tangan kanan di $\vec{P}_R = (0.40, 0.05, 0.40)\text{ m} \implies \rho = 0.18\text{ m}$ ($|0.18 - 0.18| \le 0.06 \implies \text{on\_circle} = \text{true}$).
   - Perubahan sudut per frame $\Delta t = 0.0167\text{ s}$ adalah $|\Delta\theta| = 0.09425\text{ rad}$:
     $f_{\text{ukur}} = \frac{0.09425 / 0.0167}{2\pi} = \mathbf{0.8988\text{ Hz}}$.
     Rasio deviasi: $\frac{|0.8988 - 0.75|}{0.75} = \mathbf{0.1984} \le 0.25 \implies \text{in\_band} = \mathbf{true}$.
     Energi perisai bertambah $+10/\text{s}$ dan mencatat poin kombo setiap $1.0\text{ s}$.

#### g) Kasus Batas (*Edge Cases*)
- **Cheat Goyangan Sudut Sempit**: Karena rumus menggunakan `absf(d_angle)` tanpa mengakumulasi putaran $360^\circ$ penuh, pemain dapat mengayunkan tangan bolak-balik dalam busur kecil $20^\circ$ pada radius $0.18\text{ m}$ dengan kecepatan sudut $0.75\text{ Hz}$ untuk mengisi energi perisai tanpa pernah memutar lingkaran penuh!

---

### 8. `M08` — Neck Mobility ("Recon Scanner")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M08ReconScanner` ([m08_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M08_RECON_SCANNER`, judul UI: `"M08: Recon Scanner (Neck Mobility)"` ([enums.gd:97](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L97)), Safety Level: `LEVEL_B`.
- **Di Markdown**: *M08 — Neck Mobility and Far Focus ("Recon Scanner")* ([10-m08-recon-scanner.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/10-m08-recon-scanner.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Active Cervical Axial Rotation Stretch* (menolehkan kepala secara perlahan ke kiri dan kanan dan menahan sejenak di rentang nyaman).
- **Otot Target**: *Sternocleidomastoideus* (SCM), *splenius capitis*, *scalenus*, dan *levator scapulae*.
- **Tempo & Efektivitas**: Kecepatan putar sudut rendah ($\le 60^\circ/\text{s}$) sangat krusial untuk mencegah refleks regang otot (*stretch reflex*) dan pusing vestibular (*cervicogenic dizziness*).

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HEAD_ROTATION_3DoF`: Membaca vektor orientasi depan kepala (`head_fwd_local_spec`) dan kecepatan rotasi yaw kepala (`head_speed_deg_s`) di [m08_mechanic.gd:35-38](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd#L35-L38).
  - Satu-satunya mekanik yang murni mematuhi batas input `HEAD_ROTATION_3DoF`!

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli**: Peregangan rotasi leher servikal + aturan *20-20-20* relaksasi mata optik.
2. **Kendala Optik VR**: Headset VR memiliki jarak fokus lensa tetap ($\sim 1.3\text{–}2.0\text{ m}$), sehingga menatap objek jauh di dalam dunia virtual tidak merelaksasi otot siliaris mata (`STATED_IN_SOURCE`: [10-m08-recon-scanner.md:46](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/10-m08-recon-scanner.md#L46)); Quest 2/3 tidak memiliki pelacak bola mata (*eye tracking*).
3. **Proksi di Dalam Game**: Mengganti *eye gaze* dengan *head reticle pointing*. Target diletakkan di cakrawala arena ($d = 2.4\text{ m}$) pada sudut $\psi_t = \pm \text{clamp}(k \cdot \psi_{\text{neck}}, 15^\circ, 65^\circ)$ dengan toleransi retikel $\pm 3.0^\circ$ dan batas kecepatan $\le 60^\circ/\text{s}$ selama $1.0\text{ s}$.
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**: Sudut toleh target $\psi_t$ membesar seiring faktor $k \in \{0.60, 0.75, 0.85\}$.
5. **Vonis Fidelitas**: **`FAITHFUL`** (untuk rotasi servikal yaw) — Mengukur rotasi yaw kepala secara langsung dan menegakkan batas kecepatan sudut $\le 60^\circ/\text{s}$ secara presisi.

#### e) Tabel Kriteria Keberhasilan Per Level (`M08`)

| Level | Faktor $k$ | Sudut Target $\psi_t$ (Default $\psi_L=70^\circ, \psi_R=65^\circ$) | Toleransi Retikel | Batas Kecepatan Putar $\omega_{\max}$ | Durasi Tahan Dwell | Bonus Halus | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **`Gentle`** | `0.60` | Kiri: `-42.0°`, Kanan: `+39.0°` | $\pm 3.0^\circ$ | $\le 60.0^\circ/\text{s}$ | `1.00 s` | $+10\text{ pts}$ jika $\omega \le 60^\circ/\text{s}$ sepanjang scan | [m08_mechanic.gd:35-70](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd#L35-L70), [mechanics_math.gd:203-236](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L203-L236) |
| **`Standard`** | `0.75` | Kiri: `-52.5°`, Kanan: `+48.75°` | $\pm 3.0^\circ$ | $\le 60.0^\circ/\text{s}$ | `1.00 s` | $+10\text{ pts}$ | [m08_mechanic.gd:35-70](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd#L35-L70) |
| **`Active`** | `0.85` | Kiri: `-59.5°`, Kanan: `+55.25°` | $\pm 3.0^\circ$ | $\le 60.0^\circ/\text{s}$ | `1.00 s` | $+10\text{ pts}$ | [m08_mechanic.gd:35-70](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd#L35-L70) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M08`)
1. **Ekstraksi Yaw Kepala & Kecepatan Sudut**:
   $$\psi_{\text{head}} = \text{rad\_to\_deg}\big(\text{atan2}(f_x, \max(0.01, f_z))\big), \quad \omega_h = \frac{|\psi_{\text{head}}(t) - \psi_{\text{head}}(t-\Delta t)|}{\Delta t}$$
2. **Akumulasi Dwell Timer (`MechanicsMath.m08_step_scan_dwell`)**:
   $$T_{\text{dwell}}(t+\Delta t) = \begin{cases} T_{\text{dwell}}(t) + \Delta t & \text{jika } |\psi_{\text{head}} - \psi_t| \le 3^\circ \land \omega_h \le 60^\circ/\text{s} \\ T_{\text{dwell}}(t) \text{ (DIJEDA)} & \text{jika } \omega_h > 60^\circ/\text{s} \\ \max(0, T_{\text{dwell}}(t) - 0.5\Delta t) & \text{jika } |\psi_{\text{head}} - \psi_t| > 3^\circ \land \omega_h \le 60^\circ/\text{s} \end{cases}$$
3. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-23`, Level `Standard`, Target Kanan)**:
   - Target kanan: $\psi_t = +48.75^\circ$.
   - Pemain mengarahkan kepala pada $\psi_{\text{head}} = +47.5^\circ$ (selisih $1.25^\circ \le 3.0^\circ$) dan telah menahan selama $T_{\text{dwell}} = 0.55\text{ s}$.
   - Kepala tersentak cepat pada frame berikutnya dengan kecepatan $\omega_h = 90^\circ/\text{s} > 60^\circ/\text{s}$:
     Timer dwell **tetap bernilai `0.55 s` (tidak ter-reset)**, bendera `show_slower_cue` aktif, dan bonus kehalusan gugur (`_smooth_all_the_way = false`).
   - Ketika kepala kembali stabil ($\omega_h \le 60^\circ/\text{s}$) selama $0.45\text{ s}$ berikutnya, timer mencapai $0.55 + 0.45 = 1.00\text{ s} \implies$ **SCAN TUNTAS**.

#### g) Kasus Batas (*Edge Cases*)
- **Memutar Kursi Kantor Alih-alih Leher**: Jika pemain duduk di kursi putar dan memutar kursi sementara leher kaku, headset tetap membaca perubahan yaw. Oleh karena itu `M08` dimasukkan ke dalam `SafetyLevel.LEVEL_B` yang meminta konfirmasi kursi stabil tanpa roda sebelum ronde dimulai.

---

### 9. `M09` — Elbow Flexion and Wrist Pour ("Potion Brewer")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M09PotionBrewer` ([m09_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M09_POTION_BREWER`, judul UI: `"M09: Potion Brewer (Curl & Wrist Pour)"` ([enums.gd:98](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L98)).
- **Di Markdown**: *M09 — Elbow Flexion and Wrist Pour ("Potion Brewer")* ([11-m09-potion-brewer.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/11-m09-potion-brewer.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Biceps Curl & Forearm Pronation/Supination* (fleksi siku yang diakhiri dengan memutar pergelangan tangan).
- **Otot Target**: *Biceps brachii*, *brachialis*, *brachioradialis*, *pronator teres*, dan *supinator*.
- **Tempo & Efektivitas**: Melatih sendi siku dan meredakan ketegangan pergelangan tangan akibat mengetik (*anti-Repetitive Strain Injury / RSI*).

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - `HAND_POSITION`: Posisi 3D tangan aktif untuk mengambil vial dan mengukur jarak tangan ke bahu (`dist_to_shoulder = hand_pos.distance_to(shoulder)`) di [m09_mechanic.gd:48-68](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L48-L68).
  - **`OTHER` (`HAND_ROTATION_ROLL`)**: Membaca rotasi roll sumbu Z kontroler (`rad_to_deg(left_controller.rotation.z)` / `right_controller.rotation.z`) untuk mendeteksi `wrist_roll >= 60.0°` di [m09_mechanic.gd:74](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L74).

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli**: *Biceps Curl* dumbel + peregangan rotasi pronasi pergelangan tangan anti-RSI.
2. **Kendala Posisi Duduk**: Tanpa barbel, curl di udara terasa tanpa beban; gerakan melempar ramuan berisiko melepaskan kontroler.
3. **Proksi di Dalam Game**:
   - Fleksi siku diukur dari pengurangan jarak tangan ke bahu dari $d_{\text{ext}} = 0.85 L_{\text{arm}}$ ke $d_{\text{curl}} = 0.35 L_{\text{arm}} + 0.05\text{ m}$.
   - Ditambahkan **efek beban visual (*exponential visual drag*)** dengan konstanta waktu $\tau = 0.20\text{ s}$ di mana vial tertinggal di belakang tangan saat ditarik.
   - Penuangan diukur dari putaran roll kontroler $\ge 60^\circ$ selama $1.0\text{ s}$.
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**: Ambang geometris bergantung pada panjang lengan $L_{\text{arm}}$, konstan di ketiga level.
5. **Vonis Fidelitas**: **`FAITHFUL`** — Berhasil mereplikasi fleksi siku geometris dan rotasi supinasi/pronasi pergelangan tangan secara langsung.

#### e) Tabel Kriteria Keberhasilan Per Level (`M09`)

| Level | Jarak Ambil Bahan $d_{\text{ext}}$ ($L_{\text{arm}}=0.60\text{ m}$) | Toleransi Tangkap | Ambang Selesai Curl ke Bahu | Konstanta Visual Drag $\tau$ | Syarat Tuang Pergelangan | Bonus Tuang | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **`Gentle` / `Standard` / `Active`** *(Identik)* | $0.85 L_{\text{arm}} = 0.510\text{ m}$ | $\le 0.16\text{ m}$ | $\le 0.35 L_{\text{arm}} + 0.05\text{ m}$ ($0.260\text{ m}$) | `0.20 s` | $|\text{wrist\_roll}| \ge 60.0^\circ$ selama `1.00 s` | $+50\text{ pts}$ | [m09_mechanic.gd:52-84](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L52-L84), [mechanics_math.gd:241-258](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L241-L258) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M09`)
1. **Jarak Fleksi Siku**:
   $$d_{\text{ext}} = 0.85 \cdot L_{\text{arm}}, \quad d_{\text{curl}} = 0.35 \cdot L_{\text{arm}} + 0.05\text{ m}$$
2. **Filter Visual Drag Orde Pertama**:
   $$\alpha = 1 - e^{-\Delta t / 0.20}, \quad \vec{P}_{\text{obj}}(t+\Delta t) = \vec{P}_{\text{obj}}(t) + \alpha \big(\vec{P}_{\text{hand}}(t) - \vec{P}_{\text{obj}}(t)\big)$$
3. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-24`, $L_{\text{arm}} = 0.52\text{ m}$, Frame Rate 72 Hz $\implies \Delta t = 0.01389\text{ s}$)**:
   - $d_{\text{ext}} = 0.85 \times 0.52 = 0.442\text{ m}$, $d_{\text{curl}} = 0.35 \times 0.52 + 0.05 = 0.182 + 0.05 = \mathbf{0.232\text{ m}}$.
   - Rasio penutupan celah visual per frame: $\alpha = 1 - e^{-0.01389 / 0.20} = \mathbf{0.06709}$ ($6.71\%$).
   - Pada kecepatan tarik $0.50\text{ m/s}$, jarak tertinggal tunak adalah $v \cdot \tau = 0.50 \times 0.20 = \mathbf{0.10\text{ m}}$.
   - Setelah curl selesai, memutar pergelangan hingga roll $= 65^\circ \ge 60^\circ$ selama $1.0\text{ s}$ memberikan bonus $+50\text{ poin}$.

#### g) Kasus Batas (*Edge Cases*)
- **Menuang di Luar Posisi Kawah**: Pada baris 73 [m09_mechanic.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L73), setelah curl selesai kode hanya mengecek `if wrist_roll >= 60.0:` tanpa memvalidasi apakah koordinat horizontal tangan berada tepat di atas kawah `_cauldron_x_m`.

---

### 10. `M10` — Overhead Reach with Side Bend ("Laser Evader")

#### a) Nama Latihan
- **Di Kode (`VERIFIED_IN_CODE`)**: `M10LaserEvader` ([m10_mechanic.gd:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L1)), ID enum `ZenoEnums.MechanicId.M10_LASER_EVADER`, judul UI: `"M10: Laser Evader (Side Bend)"` ([enums.gd:99](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L99)), Safety Level: `LEVEL_B`.
- **Di Markdown**: *M10 — Overhead Reach with Side Bend ("Laser Evader")* ([12-m10-laser-evader.md:1](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/12-m10-laser-evader.md#L1)).

#### b) Inspirasi Latihan Dunia Nyata (`EXTERNAL_KNOWLEDGE`)
- **Latihan Asli**: *Seated Lateral Trunk Flexion / Side Bend Stretch* (mencondongkan batang tubuh ke samping sambil mengangkat satu/kedua lengan ke atas untuk meregangkan otot rusuk lateral).
- **Otot Target**: *Quadratus lumborum*, *obliquus externus & internus*, dan *latissimus dorsi*.

#### c) Saluran Input yang Diterima (*Accepted Input*)
- **Saluran Input Aktual (`VERIFIED_IN_CODE`)**:
  - **`HEAD_POSITION` (Translasi Kepala — Di Luar Konteks Desain Seated 3DoF!)**: Membaca translasi horizontal kepala `x_head := head_local_spec.x - GameFlow.seat_anchor_local_spec.x` di [m10_mechanic.gd:43](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L43).
  - **KONTRADIKSI / PELANGGARAN DESAIN (`CONTRADICTION`)**:
    - Draf Markdown ([12-m10-laser-evader.md:23](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/12-m10-laser-evader.md#L23)) mengklaim pemain harus memegang rel di atas kepala dengan tombol grip. Di kode runtime, objek `Overhead Rail` hanya elemen visual 3D; parameter tangan `_curr_left_local_spec` dan `_curr_right_local_spec` tidak pernah dibaca!

#### d) Silsilah Desain (*Design Lineage*)
1. **Gerakan Asli**: Condong lateral tubuh dengan tangan memegang pegangan atas.
2. **Kendala Posisi Duduk**: Mencondongkan tubuh terlalu jauh ($> 0.30\text{ m}$) berisiko membuat pemain jatuh dari kursi.
3. **Proksi di Dalam Game**: Dinding laser bergerak maju dari $z = 1.4\text{ m}$ ke $0.15\text{ m}$ pada kecepatan $0.45\text{ m/s}$. Pemain harus menempatkan kepala di celah aman $g = \pm \min(k \cdot \Delta x_{\max}, 0.25\text{ m})$ dengan toleransi $\pm 0.08\text{ m}$, sementara pagar pengaman `LeanMonitor` dilonggarkan khusus untuk M10 menjadi $\min(\Delta x_{\max} + 0.05, 0.30\text{ m})$ (`AT-10` & `AT-25`, [safety_monitors.gd:43-44](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/safety/safety_monitors.gd#L43-L44)).
4. **Progresi Level (`Gentle` → `Standard` → `Active`)**: Celah aman bergeser lebih jauh seiring $k \in \{0.60, 0.75, 0.85\}$.
5. **Vonis Fidelitas**: **`APPROXIMATION`** — Mengukur pergeseran lateral kepala secara akurat, tetapi kehilangan komponen jangkauan lengan atas (*overhead reach*) karena tangan tidak divalidasi.

#### e) Tabel Kriteria Keberhasilan Per Level (`M10`)

| Level | Faktor $k$ | Celah Aman $g$ ($\Delta x_{\max,L}=0.30\text{ m}, \Delta x_{\max,R}=0.20\text{ m}$) | Toleransi Celah | Batas Pagar Keamanan Condong | Kecepatan Dinding | Kondisi Gagal (*Miss* / Jeda) | Sumber File (`VERIFIED_IN_CODE`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- | :--- |
| **`Gentle`** | `0.60` | Kiri: `-0.180 m`, Kanan: `+0.120 m` | $\pm 0.08\text{ m}$ | Kiri: `0.30 m`, Kanan: `0.25 m` | `0.45 m/s` ($2.78\text{ s}$) | Miss jika $|x_{\text{head}} - g| > 0.08\text{ m}$ saat $z \le 0.15\text{ m}$; Jeda jika $|x_{\text{head}}| \ge \text{batas}$ | [m10_mechanic.gd:39-72](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L39-L72), [mechanics_math.gd:263-283](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/mechanics_math.gd#L263-L283) |
| **`Standard`** | `0.75` | Kiri: `-0.225 m`, Kanan: `+0.150 m` | $\pm 0.08\text{ m}$ | Kiri: `0.30 m`, Kanan: `0.25 m` | `0.45 m/s` | Sama | [m10_mechanic.gd:39-72](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L39-L72) |
| **`Active`** | `0.85` | Kiri: `-0.250 m` (cap), Kanan: `+0.170 m` | $\pm 0.08\text{ m}$ | Kiri: `0.30 m`, Kanan: `0.25 m` | `0.45 m/s` | Sama | [m10_mechanic.gd:39-72](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L39-L72) |

#### f) Pipeline Pemrosesan Input & Perhitungan Numerik (`M10`)
1. **Evaluasi Celah Aman**:
   $$g = \text{sign} \cdot \min(k \cdot |\Delta x_{\max}|, 0.25), \quad \theta_{\text{pause}} = \min(|\Delta x_{\max}| + 0.05, 0.30)$$
   $$\text{success} = (|x_{\text{head}} - g| \le 0.08\text{ m}) \land (|x_{\text{head}}| < \theta_{\text{pause}})$$
2. **Contoh Perhitungan Numerik Riil (Uji Penerimaan `AT-25`, Level `Active`, $\Delta x_{\max,R} = 0.28\text{ m}, k = 0.85$)**:
   - $g = +1.0 \times \min(0.85 \times 0.28, 0.25) = \mathbf{+0.238\text{ m}}$.
   - $\theta_{\text{pause}} = \min(0.28 + 0.05, 0.30) = \mathbf{0.30\text{ m}}$.
   - Rentang celah sah: $[0.238 - 0.08, 0.238 + 0.08] = [0.158\text{ m}, 0.318\text{ m}]$.
   - Kasus A (Kepala condong berlebihan di $x_{\text{head}} = 0.30\text{ m}$): Walaupun berada di rentang celah, syarat $|0.30| < 0.30$ bernilai **`false`** $\implies$ **GAGAL (Diputus oleh pagar pengaman!)**.
   - Kasus B (Kepala tepat di $x_{\text{head}} = 0.22\text{ m}$): $|0.22 - 0.238| = 0.018\text{ m} \le 0.08\text{ m}$ dan $0.22 < 0.30\text{ m} \implies$ **SUKSES (Dinding laser terhindar!)**.

#### g) Kasus Batas (*Edge Cases*)
- **Pergeseran Posisi Duduk Statis**: Karena $x_{\text{head}}$ dihitung relatif terhadap `seat_anchor_local_spec.x`, jika pemain bergeser duduk tanpa melakukan *Recenter*, offset statis tersebut akan terbaca sebagai condong tubuh permanen.

---

## STEP 3 — RINGKASAN AUDIT, KONTRADIKSI, & PELANGGARAN INPUT

### 3.1 Tabel Ringkasan Seluruh Latihan

| ID | Nama Latihan | Status Implementasi | Level | Saluran Input Aktual | Vonis Fidelitas |
| :--- | :--- | :--- | :---: | :--- | :---: |
| **`M01`** | Asteroid Brawler (*Seated Boxing*) | `FULLY_IMPLEMENTED` | 3 | `HAND_POSITION` (+ `HEAD_POSITION` monitor) | `APPROXIMATION` |
| **`M02`** | Fruit Harvester (*Overhead Reach*) | `FULLY_IMPLEMENTED` | 3 | `HAND_POSITION` (+ `HEAD_POSITION` monitor) | `FAITHFUL` |
| **`M03`** | Glider Pilot (*Side Arm Raise*) | `PARTIAL` | 1 efektif *(3 di config)* | `HAND_POSITION` (selisih $y_R - y_L$) | `ABSTRACTED` |
| **`M04`** | Turret Gunner (*Trunk Twist*) | `FULLY_IMPLEMENTED` | 3 | `HAND_POSITION` (titik tengah 2 tangan) | `APPROXIMATION` |
| **`M05`** | Cosmic Tug-of-War (*Seated Row*) | `PARTIAL` | 3 | `HAND_POSITION` (1 tangan saja akibat bug) | `APPROXIMATION` |
| **`M06`** | Force Blast (*Forward Press*) | `FULLY_IMPLEMENTED` | 3 | `HAND_POSITION` (komponen $Z$ kedua tangan) | `APPROXIMATION` |
| **`M07`** | Shield Generator Crank (*Arm Circles*) | `PARTIAL` | 3 | `HAND_POSITION` (tangan kanan saja) | `APPROXIMATION` |
| **`M08`** | Recon Scanner (*Neck Mobility*) | `PARTIAL` | 3 | `HEAD_ROTATION_3DoF` (vektor yaw & kecepatan yaw) | `FAITHFUL` |
| **`M09`** | Potion Brewer (*Curl & Wrist Pour*) | `PARTIAL` | 1 efektif *(3 di config)* | `HAND_POSITION` + `OTHER` (`HAND_ROTATION_ROLL`) | `FAITHFUL` |
| **`M10`** | Laser Evader (*Side Bend*) | `PARTIAL` | 3 | **`HEAD_POSITION`** (translasi horizontal kepala) | `APPROXIMATION` |
| **—** | Shoulder Rolls / Rotasi Bahu | `ONLY_IN_MARKDOWN` | — | — | `LOST` |
| **—** | Seated Swimming Motion | `ONLY_IN_MARKDOWN` | — | — | `LOST` |
| **—** | Far-Look Break (20 s Passthrough) | `ONLY_IN_MARKDOWN` | — | — | `LOST` |
| **—** | Elbow Flexion and Extension | `ONLY_IN_MARKDOWN` | — | — | `LOST` (Digabung ke M09) |

---

### 3.2 Daftar Lengkap Kontradiksi: Draf Markdown vs Kode Aktual (`CONTRADICTION`)

| # | Mekanik / Fitur | Klaim di Dokumen Spesifikasi Markdown | Realitas di Kode Sumber GDScript (`VERIFIED_IN_CODE`) |
| :-: | :--- | :--- | :--- |
| **1** | **`M03 Glider Pilot` — Pengecekan Sudut Sayap Abduksi** | [05-m03-glider-pilot.md:34-46](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/05-m03-glider-pilot.md#L34-L46): Kedua lengan wajib diangkat ke samping pada sudut abduksi `|θ − θ_target| ≤ 15°` (`60° / 75° / 90°`) untuk mendapat bonus `+10 pts/s`. | [m03_mechanic.gd:37-49](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m03_glider_pilot/m03_mechanic.gd#L37-L49): `m03_compute_wing_target_offset` tidak dipanggil, sudut $\theta$ tidak dicek, dan bonus $+10\text{ pts/s}$ diberikan **tanpa syarat** walaupun tangan di depan perut. |
| **2** | **`M05 Cosmic Tug-of-War` — Dua Tangan, Tombol Grip, & Batas Waktu** | [07-m05-cosmic-tug-of-war.md:23-35](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/07-m05-cosmic-tug-of-war.md#L23-L35): Menarik dengan kedua tangan sambil menahan tombol *grip* dalam jendela waktu kayuhan $T_s = 2.0\text{ s}$ (jika lewat waktu, puing hanyut kembali). | [m05_mechanic.gd:33-48](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m05_cosmic_tug_of_war/m05_mechanic.gd#L33-L48): Memanggil `pick_hand_for_spawn(0)` (selalu tangan kiri di mode 2 tangan), tombol *grip* tidak dicek, dan tidak ada timer batas waktu kayuhan $2.0\text{ s}$. |
| **3** | **`M07 Shield Crank` — Tangan Kiri & Arah Putaran** | [09-m07-shield-generator-crank.md:23-24](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/09-m07-shield-generator-crank.md#L23-L24): Memutar kedua engkol dan wajib membalikkan arah putaran (*clockwise* vs *counter-clockwise*) tiap $10\text{ s}$. | [m07_mechanic.gd:47-56](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m07_shield_generator_crank/m07_mechanic.gd#L47-L56): Hanya mengevaluasi `curr_right_local_spec` (tangan kiri diabaikan) dan menggunakan `absf(d_angle)` sehingga arah putaran tidak pernah divalidasi. |
| **4** | **`M10 Laser Evader` — Pegangan Rel Atas & Durasi Celah** | [12-m10-laser-evader.md:23-32](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/12-m10-laser-evader.md#L23-L32): Wajib memegang rel atas dengan tombol *grip*, batas miring kepala $\le 25^\circ$, dan kepala harus berada di celah selama $1.0\text{ s}$. | [m10_mechanic.gd:21-58](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L21-L58): Objek rel atas hanya visual; posisi tangan, tombol *grip*, dan *head roll* tidak dicek; evaluasi hanya satu kali saat $z_{\text{wall}} \le 0.15\text{ m}$. |
| **5** | **`M09 Potion Brewer` — Posisi di Atas Kawah Saat Menuang** | [11-m09-potion-brewer.md:23-31](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/11-m09-potion-brewer.md#L23-L31): Tangan wajib berada tepat di atas kawah yang bergerak sambil memutar pergelangan $\ge 60^\circ$. | [m09_mechanic.gd:73-80](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m09_potion_brewer/m09_mechanic.gd#L73-L80): Kode hanya mengecek `if wrist_roll >= 60.0:` tanpa memvalidasi jarak horizontal tangan ke kawah `_cauldron_x_m`. |
| **6** | **`M04 Turret Gunner` — Batas Jarak Tangan ke Dada** | [06-m04-turret-gunner.md:25](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/06-m04-turret-gunner.md#L25) & `status_hint` [m04_mechanic.gd:14](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L14): Jarak tangan ke dada wajib $\le 0.35\text{ m}$. | [m04_mechanic.gd:36](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m04_turret_gunner/m04_mechanic.gd#L36): Kode runtime mengecek `mid_local.length() <= 0.45` ($0.45\text{ m}$, bukan $0.35\text{ m}$). |
| **7** | **`M08 Recon Scanner` — Jarak Target, Pitch, & Far-Look Break** | [10-m08-recon-scanner.md:25-32](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/MarkdownGuideForAIReconstruction/10-m08-recon-scanner.md#L25-L32): Jarak target $10\text{ m}$, batas pitch $\pm 20^\circ$, dan jeda relaksasi mata *Far-look break* $20\text{ s}$ via passthrough. | [m08_mechanic.gd:35-69](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m08_recon_scanner/m08_mechanic.gd#L35-L69): Target ditempatkan pada $d = 2.4\text{ m}$, sudut pitch tidak dicek, dan jeda passthrough $20\text{ s}$ tidak diimplementasikan. |

---

### 3.3 Audit Pelanggaran Saluran Input terhadap Desain Duduk (*Inputs Outside Intended Seated Design*)

Konteks desain menetapkan bahwa hanya **`HEAD_ROTATION_3DoF`**, **`HAND_POSITION`**, dan **`HAND_POSE`** yang boleh memengaruhi gameplay. Berikut adalah temuan komponen yang melanggar batasan ini:

1. **`M10 Laser Evader` Membaca Translasi Kepala (`HEAD_POSITION`) untuk Menghitung Condong Tubuh (`TORSO_LEAN`)**:
   - Di [m10_mechanic.gd:43](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/m10_laser_evader/m10_mechanic.gd#L43), keberhasilan menghindar dinding dihitung langsung dari translasi 3D headset: `var x_head := head_local_spec.x - GameFlow.seat_anchor_local_spec.x`.
2. **`LeanMonitor` & Penyesuaian `BodyFrame` Membaca Translasi Kepala 3D (`HEAD_POSITION`)**:
   - Di [main.gd:228-253](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L228-L253), koordinat translasi global headset (`xr_camera.global_position`) dipantau setiap frame untuk menjeda permainan jika condong lateral $> 0.20\text{ m}$ dan menyesuaikan tinggi dada `origin_spec.y`.
3. **Absennya Penggunaan Gestur Tangan `HAND_POSE` di Seluruh Latihan**:
   - Meskipun profil Hand Tracking OpenXR diaktifkan, **tidak ada satu pun mekanik di Godot yang membaca gestur jari/kepalan tangan (`HAND_POSE`)**. Pukulan tinju di `M01`, memetik buah di `M02`, dan menarik tali di `M05` murni mengecek koordinat ujung `XRController3D` (`HAND_POSITION`).
4. **Pembacaan Tombol Kontroler Fisik (`CONTROLLER_BUTTON`)**:
   - Tombol fisik kontroler (`trigger_click`, `ax_button`, `by_button`, `menu_button` di [main.gd:298-322](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L298-L322)) digunakan untuk kalibrasi, navigasi menu, dan jeda darurat.

---

### 3.4 Hal-Hal yang Tidak Dapat Diverifikasi (`NOT_FOUND`) & Kebutuhan Data

1. **Teks Asli Konsep Survei**:
   - **Status**: `NOT_FOUND`. Pertanyaan 8 dan 11 pada file [UserResponse on Idea.csv](file:///home/ramirez/XR-FP/Ideation/UserResponse%20on%20Idea.csv) merujuk pada *"konsep di atas"*, namun paragraf deskripsi konsep yang diperlihatkan kepada responden tidak tersimpan di repositori.
2. **Riwayat Commit Sebelum `ace93a7b` (16 Nov 2026)**:
   - **Status**: `NOT_FOUND`. Proyek pertama kali di-push dalam bentuk *squash commit* yang memuat seluruh aset Unity dan Godot sekaligus. Evolusi baris-demi-baris sebelum 16 November 2026 hanya dapat diperkirakan melalui stempel waktu file (`9 Nov` untuk draf ideasi dan `14–15 Nov` untuk skrip GDScript).
3. **Dokumen Persetujuan Klinis / Fisioterapis**:
   - **Status**: `NOT_FOUND`. Dokumen [Proposal-Unfixed.md:213](file:///home/ramirez/XR-FP/Ideation/Proposal-Unfixed.md#L213) mencatat perlunya peninjauan fisioterapis terhadap batasan sudut abduksi bahu ($60^\circ$); berkas hasil peninjauan fisioterapis resmi belum ditemukan di repositori.
