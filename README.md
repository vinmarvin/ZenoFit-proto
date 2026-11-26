# ZenoFit — Seated Upper-Body VR Active-Break Game

Repositori proyek **ZenoFit** (*Extended Reality · EF234711 / EA234505 · Group 4 — Lebah Ganteng*).

> **Arah & Target Utama Produk (Kesepakatan Tim):** ZenoFit adalah game VR *active-break* duduk untuk **lazy geeks / couch potatoes**—mereka yang malas bergerak dan terlalu sering beraktivitas di depan layar (pekerja/mahasiswa di depan layar, *gamers akut*, maupun individu rumahan/*ansos* yang enggan berolahraga di luar). Aksesibilitas untuk keterbatasan tungkai bawah tetap terjaga sebagai manfaat sekunder (*curb-cut effect*).

## Struktur Repositori

Repositori ini ditata menjadi **3 folder utama** beserta aturan workspace (`AGENTS.md`):

```text
XR-FP/
├── AGENTS.md   # Aturan workspace, target audiens tim, & batas arsip mata kuliah
├── berkas/     # Seluruh dokumen proyek, riset, arsip penilaian kuliah, audit, & referensi
├── godot/      # Prototipe aktif Godot 4.7 (OpenXR — PICO 4 Ultra & Meta Quest)
└── asset/      # Aset 3D mentah asli (GLB / OBJ)
```

### 1. `berkas/` — Dokumen & Riset Proyek

- [`berkas/BerkasFP/giga-ef234711-2026-final-project-group-4-main/`](./berkas/BerkasFP/giga-ef234711-2026-final-project-group-4-main/) — Arsip pertanggungjawaban administratif & analisis penilaian mata kuliah sebesar **10%** (**`GA3` 5%** dan **`GA4` 5%**). Proposal Week 8 di dalamnya sudah lewat dan bersifat historis (bukan spesifikasi produk/audiens aktif).
- [`berkas/Exercise Analysis/`](./berkas/Exercise%20Analysis/) — Data survei anonim ([`Jaras Pengguna.csv`](./berkas/Exercise%20Analysis/Jaras%20Pengguna.csv)) dan literatur referensi latihan duduk aman (`Exercise References/`).
- [`berkas/GodotDocs/`](./berkas/GodotDocs/) — Dokumentasi resmi ZenoFit v1.0: [`AGENTS.md`](./berkas/GodotDocs/AGENTS.md), spesifikasi AI 1:1 ([`AI-Spec/`](./berkas/GodotDocs/AI-Spec/00-README.md)), dan panduan pengembang ([`DeveloperGuide/`](./berkas/GodotDocs/DeveloperGuide/01-Architecture-And-How-It-Works.md)).

### 2. `godot/` — Prototipe Godot 4.7 (`ZenoFit v1.0`)

- Engine: **Godot 4.7.2** (`GDScript`, `gl_compatibility`, OpenXR `Local / Seated Reference Space`).
- **7 Latihan Terkurasi (Kursi Standar Non-Putar):** `Board Smash`, `Wide Split`, `Sky Reach`, `Orbit Flow`, `Wrist Twist`, `Torso Twist`, dan `Horizon Gaze`, lengkap dengan mode `Quick Break` (5 ronde), **Session Input Lock** (`Controller` / `Hand Tracking`), UI spasial *Dark-Sage Glass* 11 layar (`UI.pdf`), kamera stasioner bebas goyang, serta `Zeno` FoV-safe (`<= 24°`).
- Menjalankan *acceptance test suite* secara *headless*:

  ```bash
  godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
  ```
- *USB Screen Cast* headset VR:

  ```bash
  ./godot/scripts/cast_vr_screen.sh
  ```

### 3. `asset/` & `godot/assets/` — Aset 3D

- Seluruh aset 3D pada *build* final bersifat **generatif** (`Zeno_WithTexture.glb`, `KarateBoard.glb`) atau **diunduh dari toko aset eksternal** seperti Sketchfab (`Environment.glb`).
- Ketiganya (`Environment.glb`, `Zeno_WithTexture.glb`, `asset/Objects/KarateBoard.glb`) terintegrasi penuh di `godot/assets/`.
- `Floating Mascots.glb` lama sudah dihapus dari `godot/assets/`, dan botol air hasil *scan* GA3 (`scan_fitted.glb`) hanya digunakan untuk dokumentasi mata kuliah (tidak dimasukkan ke *build* final game).

### 4. `Gameplay` — Prototipe Sementara

Prototipe Zenofit telah dibuild dalam link ini: [zenofit-0.1.0-alpha.1](https://drive.google.com/file/d/19PzAZT0Y1dNtoJMhepti6lpTzVGm5wGo/view?usp=drive_link)

Demo Gameplay: [Demo Video](https://drive.google.com/file/d/1NiDAiHX2FdM8fLjXk2XzHL0E3n3p-VE_/view?usp=drive_link)

### 5. `Asset Provenance` — Ringkasan Aset & *Provenance Row*

- **Aset Rekonstruksi (*Real Scan* — Botol Air *Matte*, Dokumentasi GA3 Only):** Di-scan dari 58 foto via `Polycam 7.0.9` (Capture Plan V2), dibersihkan di `Blender`, skala `21,21 cm`, total **5.204 *triangles** (`ga3/scan_fitted.glb`; **hanya untuk arsip/dokumentasi tugas GA3**, tidak dimasukkan ke *build* Godot final).
- **Aset Generatif (*AI-Generated* — Maskot Zeno & Papan Karate):** Maskot **`Zeno_WithTexture.glb`** (`66.480` tris, 12 tekstur PBR) menjadi maskot aktif tunggal di `FloatingMascotCoach`; papan pemecah **`KarateBoard.glb`** (`604` tris, `Board_Intact` + `Board_Half_Left/Right` + `Splinter_1..6` + animasi `Break`) dibuat khusus via `Claude Sonnet 5.5` untuk *Board Smash*, *Wide Split*, dan *Torso Twist*.
- **Limitasi:** Bagian bawah botol direkonstruksi manual karena tertutup meja; sisi belakang/bawah maskot Zeno merupakan estimasi AI.

#### *Provenance Row* (Aset Non-*Handmade*)

| Asset                                                                     | Tool and version                            | Exact prompt or input image                                                                          | Date and account                                                      | Attempts                               | Licence and credit                                                                                   | Hand edits / Integrasi Godot |
| :------------------------------------------------------------------------ | :------------------------------------------ | :--------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- | :------------------------------------: | :--------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------- |
| **Karate Breaking Board** *(Generated — `asset/Objects/KarateBoard.glb` -> `godot/assets/KarateBoard.glb`)* | `Claude Sonnet 5.5` | Foto referensi papan kayu karate + prompt pembuatan aset 3D ekspor GLB untuk Blender/Godot (`media_1795650350273_2bda19a0.png`) | `26 Nov 2026` — Tim Zenofit | `1` | *Claude output terms* — aset objek khusus minigame *Board Smash*, *Wide Split*, dan *Torso Twist* | Hierarki mesh `Board_Intact` (`28` tris), `Board_Half_Left/Right` (`264` tris × 2), `Splinter_1..6` (`8` tris × 6, total `604` tris), tekstur kayu `wood_outer/inner`, dan animasi `Break` (`0.60 s`) dikendalikan via `godot/mechanics/karate_board_prop.gd`. |
| **Zeno Mascot** *(Generated — `Zeno_WithTexture.glb`)* | `Claude Sonnet 5.5` (free plan) + `Blender` | Input image: `ga3/gen_input.png` (desain maskot asli tim). Prompt: *"Can you create a 3D asset from this image? and i can export it. Make the asset so i can open it on Blendr or Unity"* | `12 Nov 2026` — Muhammad Naufal Dzakwan | `4` | *Claude output terms* (free plan — perlu konfirmasi); desain maskot asli tim (tanpa IP pihak ketiga). | *Rig hierarchy* bertekstur PBR (`Zeno_WithTexture.glb`, `66.480` tris, 12 tekstur PNG tertanam) digunakan penuh oleh `FloatingMascotCoach` dengan *ground rings* disembunyikan, *shadow casting* dimatikan, dan posisi *FoV-safe* (`<= 24°`). |
| **Water Bottle** *(Reconstructed — `ga3/scan_fitted.glb` — Dokumentasi GA3 Only)* | `Polycam 7.0.9` + `Blender` | 58 foto botol air permukaan *matte* (Capture Plan V2; tinggi asli `21 cm`, diameter `6,5 cm`). | `9 Nov 2026` — Muhammad Rafi Budiman *(lokasi: `[capture location]`)* | `2` *(V1 transparan gagal -> V2 matte)* | *Polycam terms* (perlu konfirmasi); catatan: mengandung merek pihak ketiga (*Starbucks*) pada botol fisik asli. | Geometri meja dihapus dan alas ditutup manual di `Blender` (`5.204` *triangles*). Disimpan hanya di arsip GA3 untuk kebutuhan dokumentasi tugas; **tidak disertakan dalam *build* Godot final**. |
| **Zen Dojo Room** *(External — `asset/Environment.glb` -> `godot/assets/Environment.glb`)* | Sketchfab Download (`GLB 1k`, `5.47 MB`) + Godot `GLTFDocument` | Model *"Japanese Traditional Room"* oleh `jrevel` (`69175f3d695d4950b0cae35ecd3294df`) | `21 Nov 2026` — Tim Zenofit | `1` *(1k GLB preset)* | **CC BY 4.0** — kredit pembuat asli **`jrevel`** di layar *Credits* & dokumentasi | Membuang 28 *node* sampel modular di luar ruangan saat runtime di `DojoEnvironmentLoader`, menonaktifkan *real-time shadow*, `CULL_DISABLED` untuk shoji, dan centering `9m × 6m` terhadap *BodyFrame* duduk. |

---

> *Catatan: ZenoFit adalah aplikasi active-break preventif, bukan perangkat medis (*not a medical device*).*

