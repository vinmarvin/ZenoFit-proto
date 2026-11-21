# ZenoFit — Seated Upper-Body VR Active-Break Game

Repositori proyek **ZenoFit** (*Extended Reality · EF234711 / EA234505 · Group 4 — Lebah Ganteng*).

## Struktur Repositori

Repositori ini ditata menjadi **3 folder utama**:

```text
XR-FP/
├── berkas/     # Seluruh dokumen proyek, riset, kontrak kuliah, audit, & referensi
├── godot/      # Prototipe aktif Godot 4.7 (OpenXR — PICO 4 Ultra & Meta Quest)
└── asset/      # Aset 3D mentah asli (GLB / OBJ)
```

### 1. `berkas/` — Dokumen & Riset Proyek
- [`berkas/BerkasFP/`](./berkas/BerkasFP/) — Salinan berkas resmi mata kuliah yang dikumpulkan ke dosen (`Final Project Proposal Contract.md`, `Asset Analysis -GA3.md`).
- [`berkas/Ideation/`](./berkas/Ideation/) — Analisis terpadu ([`Zenofit Analysis.md`](./berkas/Ideation/Zenofit%20Analysis.md)), data survei anonim ([`Jaras Pengguna.csv`](./berkas/Ideation/Jaras%20Pengguna.csv)), dan jurnal acuan (*Xu et al., 2020*).
- [`berkas/Exercise Analysis/`](./berkas/Exercise%20Analysis/) — Referensi PDF latihan duduk aman serta laporan audit forensik & pemetaan arsitektur Godot.
- [`berkas/GodotDocs/`](./berkas/GodotDocs/) — Seluruh dokumentasi spesifikasi & panduan developer Godot (`AGENTS.md`, `MarkdownGuideForAIReconstruction/`, `Artifact For Developer/`).

### 2. `godot/` — Prototipe Godot 4.7
- Engine: **Godot 4.7+** (`GDScript`, `gl_compatibility`, OpenXR `Local / Seated Reference Space`).
- Menjalankan *acceptance test suite* secara *headless*:
  ```bash
  godot --headless --xr-mode off --path godot -s res://tests/run_acceptance_tests.gd
  ```
- *USB Screen Cast* headset VR:
  ```bash
  ./godot/scripts/cast_vr_screen.sh
  ```

### 3. `asset/` — Aset Mentah Asli
- `Floating Mascots.glb` dan `Zeno.obj` (aset 3D sumber di luar proyek Godot).

---

> *Catatan: ZenoFit adalah aplikasi active-break preventif, bukan perangkat medis (*not a medical device*).*
