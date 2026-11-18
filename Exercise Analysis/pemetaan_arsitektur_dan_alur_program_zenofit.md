# Pemetaan Arsitektur Teknis & Alur Program ZenoFit (Godot 4.7)

> [!NOTE]
> **Tujuan Dokumen**: Memetakan arsitektur perangkat lunak, hierarki kontrol (*who controls what*), mesin keadaan (*state machine*), alur data pelacakan (*input & tracking pipeline*), siklus hidup ronde (*session & round lifecycle*), dan komunikasi antar-subsistem pada game VR latihan duduk *ZenoFit* berbasis **Godot 4.7** (`GodotMockup/mockup-v-1/`).

---

## 1. Peta Hirarki Arsitektur: Siapa Mengontrol Siapa (*Who Controls What*)

Arsitektur *ZenoFit* dibangun menggunakan pola **Mediator-Orchestrator** berbasis node dan *Autoload Singleton*, dipadukan dengan **Event-Driven Architecture** melalui `EventBus` global untuk mencegah ketergantungan melingkar (*circular dependencies*).

```mermaid
graph TD
    subgraph EngineAndHardware ["1. Engine & Hardware Layer"]
        OpenXR["OpenXR Runtime / Desktop Simulator"]
        ProjectGodot["project.godot (Main Scene: main.tscn)"]
    end

    subgraph AutoloadLayer ["2. Global Autoload Singletons (Service Layer)"]
        EventBus["EventBus (autoload/event_bus.gd)\nSinyal Global / Decoupled Broker"]
        Platform["Platform (autoload/platform.gd)\nOpenXR Abstraction, Haptics, Passthrough"]
        SaveService["SaveService (autoload/save_service.gd)\nJSON Persistence: user://"]
        GameFlow["GameFlow (autoload/game_flow.gd)\nMaster Game Manager & AppState Machine"]
    end

    subgraph SceneCoordinator ["3. Scene Coordinator (Controller Layer)"]
        Main["Main (main.gd / XROrigin3D)\nKoordinator Hardware, Pelacakan, Kamera, & Arena"]
    end

    subgraph HardwareNodes ["4. XR Hardware Tracker Nodes"]
        XRCamera["XRCamera3D (Headset / Mata)"]
        LeftCtrl["LeftController (XRController3D)"]
        RightCtrl["RightController (XRController3D)"]
    end

    subgraph CoreMath ["5. Core Mathematics & Coordinate Transformers"]
        SpecSpace["SpecSpace (core/spec_space.gd)\nKonversi Left-Handed <-> Right-Handed"]
        BodyFrame["BodyFrame (core/body_frame.gd)\nKoordinat Lokal Dada Seated"]
        ComfortProfile["ComfortProfile (core/comfort_profile.gd)\nData Antropometri & Jangkauan Kalibrasi"]
        ZenoGeometry["ZenoGeometry (core/geometry.gd)\nAnti-Tunnelling Segment-to-Sphere"]
        MechanicsMath["MechanicsMath (core/mechanics_math.gd)\nFormula Khusus M01-M10"]
        AdaptiveTempo["AdaptiveTempo (core/adaptive_tempo.gd)\nRegulator BPM Adaptif 8-Target"]
        ZenoScoring["ZenoScoring (core/scoring.gd)\nTimeliness, Streak, & Combo Multiplier"]
    end

    subgraph ActiveSubsystems ["6. Runtime Subsystems & Gameplay Workers"]
        CalibrationCtrl["CalibrationController (calibration/)"]
        SafetyMonitors["SafetyMonitors (safety/safety_monitors.gd)\nAutoPause, LeanMonitor, RestReminder"]
        ActiveMechanic["Active Mechanic (mechanics/m01..m10)\nTransient Gameplay Worker"]
        ArenaRoot["SessionArena (Node3D)\nContainer Visual Objek Target 3D"]
        MascotCoach["FloatingMascotCoach (mascot/)\nPelatih 3D Prosedural GLB"]
        WorldUI["ZenoWorldUI (ui/world_ui.gd)\n3D Eye-Level Billboard HUD + 2D Overlay"]
    end

    %% Relasi Kontrol & Data
    ProjectGodot --> Main
    OpenXR --> Platform
    OpenXR --> XRCamera
    OpenXR --> LeftCtrl
    OpenXR --> RightCtrl

    Main --> XRCamera
    Main --> LeftCtrl
    Main --> RightCtrl
    Main --> ArenaRoot
    Main --> MascotCoach
    Main --> WorldUI
    Main --> CalibrationCtrl
    Main --> SafetyMonitors

    GameFlow --> SaveService
    GameFlow --> AdaptiveTempo
    GameFlow --> ComfortProfile
    GameFlow --> BodyFrame

    Main -.->|Mengatur & Men-tick Per Frame| ActiveMechanic
    ActiveMechanic -.->|Membuat Mesh Target 3D| ArenaRoot

    Main --> SpecSpace
    Main --> BodyFrame

    %% Event Bus Signals
    ActiveMechanic -.->|target_hit / target_missed| EventBus
    Main -.->|button_pressed / recentered| GameFlow
    GameFlow -.->|state_changed / round_started / round_ended| EventBus
    SafetyMonitors -.->|pause_session| GameFlow
    EventBus -.->|Update Tampilan| WorldUI
    EventBus -.->|Reaksi Gestur / Demo Bentuk| MascotCoach
```

### Tabel Peran dan Tanggung Jawab Komponen

| Komponen / Script | Jenis | Siapa yang Mengontrolnya | Apa yang Dikontrol / Dimilikinya | Bukti Lokasi File (`VERIFIED_IN_CODE`) |
| :--- | :--- | :--- | :--- | :--- |
| **`GameFlowController`** | `Autoload Node` | Engine saat boot; menerima aksi dari tombol UI / input pemain. | **Penguasa Siklus Hidup Permainan**: Mengontrol mesin keadaan `AppState`, timer ronde (Intro 4s, Play 30s, Outro 2s), undian mekanik seimbang (`SessionDraw`), skor kombo (`RoundScoreTracker`), dan tempo adaptif (`AdaptiveTempo`). | [autoload/game_flow.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/autoload/game_flow.gd) |
| **`Main` (`XROrigin3D`)** | `Scene Root Node` | Scene Tree Godot (`run/main_scene`). | **Koordinator Fisik & Perangkat**: Membaca posisi hardware (`XRCamera3D`, `XRController3D`), menormalkan koordinat ke `BodyFrame`, menjalankan monitor keselamatan, menginstansiasi mekanik aktif (`M01`–`M10`), serta memperbarui `FloatingMascotCoach` dan `ZenoWorldUI`. | [main.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd) |
| **`EventBus`** | `Autoload Node` | Dipanggil oleh semua sistem sebagai penyedia sinyal. | **Pialang Pesan Global (*Message Broker*)**: Menyediakan sinyal *decoupled* seperti `state_changed`, `round_started`, `target_hit`, `session_paused`, dan `mascot_demo_requested`. | [autoload/event_bus.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/autoload/event_bus.gd) |
| **`Platform`** | `Autoload Node` | Engine OpenXR. | **Abstraksi Perangkat Keras**: Mengontrol inisialisasi OpenXR, getaran haptik kontroler (`trigger_haptic_pulse`), aktivasi kamera tembus pandang (*passthrough* alpha blend), dan sinyal *recenter*. | [autoload/platform.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/autoload/platform.gd) |
| **`SaveServiceClass`** | `Autoload Node` | Dipanggil oleh `GameFlow`. | **Penyimpanan Permanen Disk**: Membaca dan menulis profil kalibrasi (`calibration_profile.json`), riwayat sesi (`sessions.json`), dan preferensi (`settings.json`) ke direktori `user://` (atau `/tmp/zenofit_userdata/` saat headless/sandbox). | [autoload/save_service.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/autoload/save_service.gd) |
| **`MechanicBase` (Turunan `M01`–`M10`)** | `RefCounted Object` | Diinstansiasi dan di-tick setiap frame oleh `main.gd` selama state `ROUND_PLAY`. | **Pekerja Gameplay Spesifik**: Menggerakkan target minigame, memvalidasi tabrakan segmen tangan ke bola target, menghitung sudut kemudi/muatan/tahanan, dan melaporkan *hit/miss*. | [mechanics/mechanic_base.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mechanics/mechanic_base.gd) |
| **`SafetyMonitors`** | `RefCounted Objects` | Dimiliki dan dievaluasi setiap frame oleh `main.gd`. | **Pencegah Cedera Otomatis**: Memantau tangan istirahat di pangkuan (`AutoPauseMonitor` $\ge 2.0\text{ s}$), condong tubuh berlebih (`LeanMonitor` $> 0.20\text{ m}$), dan pengingat istirahat leher (`RestReminderMonitor` tiap $8\text{ menit}$). | [safety/safety_monitors.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/safety/safety_monitors.gd) |
| **`FloatingMascotCoach`** | `Node3D` (Anak `Main`) | Diperbarui per frame oleh `main.gd`. | **Pelatih Visual Interaktif**: Memuat model 3D `Floating Mascots.glb`, mendemonstrasikan gerakan mekanik aktif secara anatomis, dan bereaksi saat disentuh/ditepuk pemain. | [mascot/floating_mascot_coach.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/mascot/floating_mascot_coach.gd) |
| **`ZenoWorldUI`** | `Node3D` (Anak `Main`) | Diperbarui per frame oleh `main.gd`. | **Antarmuka 3D Setinggi Mata**: Papan billboard 3D yang mengambang mengikuti arah pandangan mata pemain (*lazy follow*), menampilkan instruksi langkah kalibrasi, petunjuk mekanik, sisa waktu, dan papan skor. | [ui/world_ui.gd](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/ui/world_ui.gd) |

---

## 2. Alur Inisialisasi Program (*Boot Sequence*)

Urutan langkah teknis dari saat aplikasi dibuka hingga menu utama siap menerima input:

```mermaid
sequenceDiagram
    autonumber
    participant Engine as Godot Engine
    participant Proj as project.godot
    participant EB as EventBus
    participant Plat as Platform
    participant Save as SaveService
    participant GF as GameFlow
    participant Main as main.tscn (Main.gd)
    participant UI as ZenoWorldUI

    Engine->>Proj: Baca konfigurasi & inisialisasi Autoload
    Proj->>EB: Instansiasi EventBus
    Proj->>Plat: Instansiasi Platform
    Proj->>Save: Instansiasi SaveService
    Proj->>GF: Instansiasi GameFlow
    GF->>Save: load_settings() & try_load_calibration_profile()
    Save-->>GF: Kembalikan settings & profil kalibrasi (jika ada)

    Engine->>Main: Muat Main Scene (res://main.tscn)
    Main->>Plat: initialize_platform()
    alt Headset VR Terdeteksi
        Plat-->>Main: is_xr_active = true, viewport.use_xr = true
    else Desktop Mode
        Plat-->>Main: is_xr_active = false (Fallback Mouse+Keyboard)
    end

    Main->>Main: _setup_environment_and_nodes() (Lampu, Platform Seated, Arena)
    Main->>Main: _setup_controllers_and_tips() (HandTip Visual & Bind Input)
    Main->>UI: Instansiasi & hubungkan sinyal tombol UI
    Main->>Main: _rebuild_body_frame_from_camera() (Kunci origin dada di bawah kamera)
    Main->>GF: complete_boot()
    GF->>GF: _transition_to(AppState.MAIN_MENU)
    GF->>EB: emit_signal("state_changed", BOOT, MAIN_MENU)
    EB->>UI: Perbarui tampilan ke panel menu utama
```

---

## 3. Mesin Keadaan Lengkap (*AppState Machine*)

Siklus hidup permainan diatur secara ketat oleh variabel `GameFlow.current_state` yang mengimplementasikan enum `ZenoEnums.AppState` ([enums.gd:4-14](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/core/enums.gd#L4-L14)):

```mermaid
stateDiagram-v2
    [*] --> BOOT: Engine Mulai
    BOOT --> MAIN_MENU: GameFlow.complete_boot()

    MAIN_MENU --> CALIBRATION: Pilih Kalibrasi / Mulai tanpa profil valid
    MAIN_MENU --> SESSION_START: Mulai Score Attack / Practice (Profil valid)

    state CALIBRATION {
        [*] --> SEAT_ANCHOR: Langkah 1 (Tinggi Duduk & Arah Depan)
        SEAT_ANCHOR --> CHEST_POINT: Langkah 2 (Titik Sternum Dada)
        CHEST_POINT --> SHOULDERS: Langkah 3 (Lebar Bahu L & R)
        SHOULDERS --> LEFT_REACH: Langkah 4 (Jangkauan Maksimal Tangan Kiri)
        LEFT_REACH --> RIGHT_REACH: Langkah 5 (Jangkauan Maksimal Tangan Kanan)
        RIGHT_REACH --> LAP_POINT: Langkah 6 (Titik Istirahat Pangkuan)
        LAP_POINT --> OBSTACLES: Langkah 7 (Tandai Halangan Meja/Kursi)
        OBSTACLES --> MODULES: Modul Opsional Level B (Twist, Neck, Lean)
        MODULES --> [*]: Selesai & Simpan ke JSON
    }

    CALIBRATION --> SESSION_START: on_calibration_finished()

    state SCORE_ATTACK_SESSION {
        SESSION_START --> ROUND_INTRO: Undi 5 Mekanik Seimbang (Round 0)
        
        ROUND_INTRO --> ROUND_PLAY: Timer 4.0 s Habis (Target Pertama Muncul)
        ROUND_PLAY --> ROUND_OUTRO: Timer 30.0 s Habis (Simpan Skor Ronde)
        
        ROUND_OUTRO --> ROUND_INTRO: Masih ada ronde (Round Index < 4)
        ROUND_OUTRO --> RESULTS: Seluruh 5 Ronde Selesai
    }

    state PAUSE_SYSTEM {
        ROUND_PLAY --> PAUSED: Intervensi Manual / Keselamatan
        ROUND_INTRO --> PAUSED: Intervensi Manual / Recenter
        ROUND_OUTRO --> PAUSED: Intervensi Manual

        state PAUSED {
            [*] --> MenungguKeputusan
            MenungguKeputusan --> ResumeCountdown: Tekan Resume / Selesai Istirahat
            MenungguKeputusan --> SubstitusiLevelA: Tolak Kursi Stabil (AT-28)
            ResumeCountdown --> [*]: Timer 3.0 s Habis
        }

        PAUSED --> ROUND_PLAY: Pulihkan State Sebelumnya
        PAUSED --> ROUND_INTRO: Pulihkan State Sebelumnya (atau setelah substitusi)
    }

    RESULTS --> SESSION_START: Main Lagi
    RESULTS --> MAIN_MENU: Kembali ke Menu Utama
    MAIN_MENU --> [*]: Keluar Aplikasi
```

### Rincian Alasan Jeda Darurat (*Pause Reasons*):
1. **`MANUAL`**: Pemain menekan tombol menu kontroler (`menu_button`) atau tombol `Esc`.
2. **`AUTO_PAUSE_LAP`**: Kedua tangan diletakkan di pangkuan ($d \le 0.15\text{ m}$ dari titik pangkuan) selama $\ge 2.0\text{ s}$ ([safety_monitors.gd:22](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/safety/safety_monitors.gd#L22)). Mode passthrough kamera otomatis aktif.
3. **`LEAN_WARNING`**: Kepala condong ke samping melampaui batas aman ($> 0.20\text{ m}$ untuk Level A, atau batas khusus untuk M10) selama $\ge 0.50\text{ s}$.
4. **`REST_REMINDER`**: Pemain telah bermain selama $8.0\text{ menit}$ berturut-turut untuk mencegah ketegangan leher akibat bobot headset.
5. **`RECENTER_REQUIRED`**: Sistem OpenXR mendeteksi tombol *recenter* ditekan; permainan menjeda seketika dan meminta konfirmasi posisi duduk baru (`AT-16`).
6. **`STABLE_CHAIR_CONFIRMATION`**: Sebelum mekanik Level B (`M04`, `M08`, `M10`) dimulai, sistem meminta konfirmasi bahwa kursi yang digunakan tidak berputar/terkunci stabil. Jika ditolak, sistem memanggil `decline_stable_chair_and_substitute()` untuk menukar mekanik ke Level A (`AT-28`).

---

## 4. Alur Pemrosesan Frame (*Per-Frame Execution Pipeline*)

Setiap frame pada fungsi `Main._process(delta)` di [main.gd:188-269](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L188-L269) mengeksekusi pipeline berurutan:

```mermaid
flowchart TD
    StartFrame["Frame Dimulai: Main._process(delta)"] --> SimInput["1. Tangani Input Desktop Simulator (Keyboard/Mouse)"]
    SimInput --> SyncCam["2. _sync_xr_camera_body_frame()<br/>Sinkronkan Ketinggian Dada Origin Y dengan Pandangan"]
    SyncCam --> TrackPoses["3. _update_tracked_poses(dt)<br/>Transformasi Posisi Kontroler ke BodyFrame & Hitung Kecepatan 3-Frame"]
    TrackPoses --> AdvTimer["4. GameFlow.advance_round_timer(delta)<br/>Kurangi Timer State (Intro 4s, Play 30s, Outro 2s, atau Resume 3s)"]
    
    AdvTimer --> CheckState{"Apakah State == ROUND_PLAY?"}
    
    CheckState -- "Tidak" --> AuxUpdate["Update Subsistem Pembantu"]
    
    CheckState -- "Ya" --> SafetyEval["5. _evaluate_safety_monitors(dt)"]
    
    SafetyEval --> AutoPauseCheck{"Tangan di Pangkuan >= 2.0 s?"}
    AutoPauseCheck -- "Ya" --> PauseLap["GameFlow.pause_session(AUTO_PAUSE_LAP)<br/>Aktifkan Kamera Passthrough"]
    
    AutoPauseCheck -- "Tidak" --> LeanCheck{"Kepala Condong > Batas Aman?"}
    LeanCheck -- "Ya" --> PauseLean["GameFlow.pause_session(LEAN_WARNING)"]
    
    LeanCheck -- "Tidak" --> RestCheck{"Waktu Bermain >= 8 Menit?"}
    RestCheck -- "Ya" --> PauseRest["GameFlow.pause_session(REST_REMINDER)"]
    
    RestCheck -- "Tidak" --> UpdateMech["6. active_mechanic.update_mechanic(...)<br/>Eksekusi Logika Target & Deteksi Tabrakan"]
    
    UpdateMech --> AuxUpdate
    
    AuxUpdate --> MascotUp["7. mascot_coach.update_coach(delta)<br/>Animasi Prosedural & Pengecekan Tepukan Tangan"]
    MascotUp --> UIUp["8. world_ui.update_ui_display(...)<br/>Perbarui Teks Papan 3D HUD & Posisikan di Depan Mata"]
    UIUp --> EndFrame["Frame Selesai"]

    PauseLap --> AuxUpdate
    PauseLean --> AuxUpdate
    PauseRest --> AuxUpdate
```

---

## 5. Pipeline Transformasi Koordinat & Deteksi Tabrakan (*Math & Geometry Pipeline*)

Seluruh perhitungan gerak pemain dan kemunculan target diisolasi dari koordinat dunia Godot agar tidak terpengaruh oleh orientasi ruangan nyata pemain:

```mermaid
flowchart LR
    subgraph WorldSpace ["1. Ruang Nyata (Godot Space)"]
        RawXR["XRController3D.global_position<br/>(+X Kanan, +Y Atas, -Z Depan)"]
    end

    subgraph SpecSpaceConv ["2. Konversi Tangan-Kiri (SpecSpace)"]
        ToSpec["SpecSpace.to_spec(p)<br/>Z_spec = -Z_godot<br/>(+X Kanan, +Y Atas, +Z Depan)"]
    end

    subgraph BodyFrameSpace ["3. Normalisasi Tubuh (BodyFrame)"]
        ToLocal["BodyFrame.from_godot_world(p)<br/>P_local = R_y(-yaw) * (P_spec - Chest_Origin)"]
    end

    subgraph AntiTunnel ["4. Anti-Tunnelling Segment Collision"]
        Seg["Garis Lintasan: P(t-dt) -> P(t)<br/>Geometry3D.get_closest_point_to_segment()"]
        Dist{"Jarak Terdekat <= (r_target + 0.04 m)?"}
    end

    subgraph ScoringPipe ["5. Evaluasi Skor & Haptik"]
        Hit["HIT! Klasifikasi Solid vs Light (v >= 0.30 m/s)<br/>Hitung Timeliness tau = 1 - t/T_life<br/>Kalikan Combo Multiplier M = 1 + streak/20"]
        Haptic["Kirim Pulsa Getar Haptik & Emit EventBus"]
    end

    RawXR --> ToSpec
    ToSpec --> ToLocal
    ToLocal --> Seg
    Seg --> Dist
    Dist -- "Ya" --> Hit
    Hit --> Haptic
    Dist -- "Tidak" --> Miss["Target Kedaluwarsa / Lepas -> MISS"]
```

---

## 6. Diagram Alur Data Saat Sesi Gameplay (*Data Flow Sequence*)

Diagram berikut menggambarkan pertukaran data waktu-nyata (*real-time*) saat seorang pemain memukul asteroid pada mekanik **`M01 Asteroid Brawler`**:

```mermaid
sequenceDiagram
    autonumber
    participant HW as XR Controller (Hardware)
    participant Main as Main.gd (_process)
    participant BF as BodyFrame
    participant M01 as M01AsteroidBrawler
    participant Geo as ZenoGeometry
    participant Scoring as ZenoScoring / RoundTracker
    participant Tempo as AdaptiveTempo
    participant Plat as Platform (Haptics)
    participant EB as EventBus
    participant UI as ZenoWorldUI
    participant Coach as FloatingMascotCoach

    HW->>Main: Posisi baru kontroler global (x, y, z)
    Main->>BF: from_godot_world(global_pos)
    BF-->>Main: curr_left_local_spec & curr_right_local_spec
    Main->>Main: Perbarui buffer kecepatan 3 frame (_left_speeds, _right_speeds)
    Main->>M01: update_mechanic(dt, poses, smoothed_speeds, ...)
    
    M01->>M01: Gerakkan asteroid mendekat: curr_pos.z -= v_a * dt
    M01->>Geo: check_valid_hand_hit(curr_pos, r_target, prev_pos, curr_pos)
    Geo-->>M01: true (Tabrakan segmen terdeteksi!)

    M01->>Scoring: record_hit(elapsed_s, lifetime_s, is_solid)
    Scoring-->>M01: return {base_points: 130, combo_points: 156, streak: 4}
    
    M01->>Tempo: record_target_outcome(true)
    Note over Tempo: Jika 8 target terakhir akurasi >= 85%, BPM naik +5

    M01->>Plat: play_haptic_solid_boxing(hand)
    Plat->>HW: trigger_haptic_pulse("haptic", 0.0, 0.70, 0.080)

    M01->>EB: emit_signal("target_hit", hand, 156, 4, true)
    
    par Respon Antarmuka & Maskot
        EB->>UI: Update skor total, kombo streak, dan efek hit
        EB->>Coach: Trigger animasi selebrasi gembira maskot
    end
```

---

## 7. Rangkuman Integrasi & Batasan Arsitektur

1. **Pemisahan Logika Matematika dan Rendering (Aturan Desain #11)**:
   - Seluruh rumus kalkulasi mekanik (`M01`–`M10`), evaluasi jangkauan kalibrasi, histeresis, dan skor ditempatkan di class statis murni tanpa ketergantungan visual (`MechanicsMath`, `BodyFrame`, `SpecSpace`, `ZenoGeometry`, `ZenoScoring`).
   - Node visual 3D target hanya bertindak sebagai representasi visual yang posisinya diperbarui melalui transformasi `body_frame.to_godot_world(pos_spec)`.
2. **Ketergantungan Siklus Terputus Melalui `EventBus`**:
   - `M01`–`M10` tidak pernah memanggil `ZenoWorldUI` atau `FloatingMascotCoach` secara langsung. Semua komunikasi keberhasilan, kegagalan, dan peringatan keselamatan melewati sinyal `EventBus`.
3. **Penyelaras Tinggi Otomatis (*Adaptive Eye-Level Alignment*)**:
   - Fungsi `_sync_xr_camera_body_frame()` pada [main.gd:228-235](file:///home/ramirez/XR-FP/GodotMockup/mockup-v-1/main.gd#L228-L235) memastikan bahwa ketika pemain menyesuaikan posisi duduk atau bantal kursi, ketinggian titik dada `origin_spec.y` secara halus diselaraskan kembali secara lerp ($18\%$ per frame) tanpa merusak kalibrasi horizontal.
