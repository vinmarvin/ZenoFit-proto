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

### 3. `asset/` — Aset Game

- `Floating Mascots.glb` dan `Zeno.obj` (aset 3D sumber di luar proyek Godot).

### 4. `Gameplay` — Prototipe Sementara

Prototipe Zenofit telah dibuild dalam link ini: [zenofit-0.1.0-alpha.1](https://drive.google.com/file/d/19PzAZT0Y1dNtoJMhepti6lpTzVGm5wGo/view?usp=drive_link)

Demo Gameplay: [Demo Video](https://drive.google.com/file/d/1NiDAiHX2FdM8fLjXk2XzHL0E3n3p-VE_/view?usp=drive_link)

### 5. `Asset Provenance` — Ringkasan Aset & *Provenance Row*

- **Aset Rekonstruksi (*Real Scan* — Botol Air *Matte*):** Di-scan dari 58 foto via `Polycam 7.0.9` (Capture Plan V2 setelah botol transparan V1 berlubang), dibersihkan di `Blender` (hapus meja & tutup alas bawah), skala `21,21 cm` (asli `21 cm`), total **5.204 *triangles** (masuk jatah 1% = `13.000`).
- **Aset Generatif (*AI-Generated* — Maskot Zeno):** Dibuat dari gambar referensi tim (`ga3/gen_input.png`) menggunakan `Claude Sonnet 5.5` (4 percobaan), dirapikan penempatan komponennya di `Blender`, dan dioptimasi dari **66.480 → 19.900 *triangles** (mendekati jatah 1,5% = `19.500`).
- **Limitasi:** Bagian bawah botol direkonstruksi manual karena tertutup meja; sisi belakang/bawah maskot Zeno merupakan estimasi AI dan animasi *stretching* penuh masih dalam pengembangan.

#### *Provenance Row* (Aset Non-*Handmade*)

| Asset                                                                     | Tool and version                            | Exact prompt or input image                                                                          | Date and account                                                      | Attempts                               | Licence and credit                                                                                   | Hand edits                                                                                           |
| :------------------------------------------------------------------------ | :------------------------------------------ | :--------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- | :------------------------------------: | :--------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------- |
| **Zeno Mascot** *(Generated — `Floating Mascots.glb` / `gen_fitted.glb`)* | `Claude Sonnet 5.5` (free plan) + `Blender` | Input image: `ga3/gen_input.png` (desain maskot asli tim). Prompt: *"Can you create a 3D asset from this image? and i can export it. Make the asset so i can open it on Blendr or Unity"* | `12 Nov 2026` — Muhammad Naufal Dzakwan                               | `4`                                    | *Claude output terms* (free plan — perlu konfirmasi); desain maskot asli tim (tanpa IP pihak ketiga). | Memperbaiki posisi bagian objek yang meleset di `Blender`, mereduksi *triangle count* dari `66.480` → `19.900`, serta menyiapkan *pivot* bahu/leher prosedural di Godot. |
| **Water Bottle** *(Reconstructed — `scan_raw.glb` / `scan_fitted.glb`)*   | `Polycam 7.0.9` + `Blender`                 | 58 foto botol air permukaan *matte* (Capture Plan V2; tinggi asli `21 cm`, diameter `6,5 cm`).       | `9 Nov 2026` — Muhammad Rafi Budiman *(lokasi: `[capture location]`)* | `2` *(V1 transparan gagal → V2 matte)* | *Polycam terms* (perlu konfirmasi); catatan: mengandung merek pihak ketiga (*Starbucks*) pada botol fisik asli. | Menghapus geometri meja yang ikut ter-scan dan menutup permukaan bawah botol secara manual di `Blender`; validasi skala `21,21 cm` (`5.204` *triangles*, tekstur `4096×4096`). |

---

> *Catatan: ZenoFit adalah aplikasi active-break preventif, bukan perangkat medis (*not a medical device*).*

