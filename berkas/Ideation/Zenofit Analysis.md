# ZenoFit Analysis — Analisa Pengguna, Landasan Riset, & Desain Gerakan Duduk

> Dokumen ini merupakan gabungan (*irisan terpadu*) dari **Analisa Pengguna (Revisi — Target: "Lazy Couch Geeks")** dan **draf awal Proposal ZenoFit**, yang telah diselaraskan dengan survei internal ([Jaras Pengguna.csv](./Jaras%20Pengguna.csv)), tinjauan jurnal **Xu et al. (2020)**, desain tema **Zen Dojo**, serta implementasi **Godot 4.7 (OpenXR Hand Tracking)** untuk **PICO 4 Ultra & Meta Quest**.  
> Tanda **`[CEK]`** menandai sitasi/angka sekunder yang disarankan untuk diverifikasi ke sumber aslinya sebelum publikasi/pengumpulan akhir.

---

## 1. Definisi Operasional Target Pengguna ("Lazy Couch Geeks")

Kata *"malas"* tidak bisa diukur secara langsung, sehingga target utama didefinisikan secara operasional dan terukur:

> **Orang dewasa muda (±18–35 tahun) yang menghabiskan banyak waktu duduk di depan layar (*gaming*, *coding*, kuliah/kerja), aktivitas fisiknya di bawah rekomendasi WHO, dan *tidak mau atau tidak sempat* pergi ke gym atau berolahraga di luar rumah.**

Tiga kriteria yang dapat diukur melalui kuesioner:
1. **Screen-heavy:** duduk di depan layar $\ge 6\text{ jam/hari}$ (di luar tidur).
2. **Insufficiently active:** $< 150\text{ menit}$ aktivitas sedang per minggu (standar WHO).
3. **Indoor-preference:** hambatan utama berolahraga adalah tidak ada waktu, malas, ruang terbatas, atau tidak nyaman di gym/tempat umum.

---

## 2. Latar Belakang Masalah & Bukti Empiris

### 2.1 Skala Masalah Global & Nasional
| Fakta | Sumber |
| :--- | :--- |
| **31% orang dewasa di dunia ($\pm 1{,}8$ miliar)** tidak cukup aktif pada 2022 (naik dari 26% pada 2010, diproyeksikan **35% pada 2030**). | WHO (2024); Strain et al. (2024), *The Lancet Global Health* |
| Di Indonesia, **37,4% penduduk usia $\ge 10$ tahun kurang aktivitas fisik** (naik dari 33,5% pada 2018 dan 26,1% pada 2013). | Survei Kesehatan Indonesia (SKI) 2023, BKPK Kemenkes RI |
| Pedoman WHO 2020 menegaskan *"some physical activity is better than none"*: menyelingi duduk dengan aktivitas intensitas apa pun—termasuk ringan—tetap bermanfaat. | Bull et al. (2020), *British Journal of Sports Medicine* |

### 2.2 Bukti Nasional: "Tidak Ada Waktu" & "Malas" sebagai Hambatan Terbesar
Menurut **SKI 2023**, alasan utama penduduk Indonesia kurang beraktivitas fisik adalah:

| Alasan | Persentase | Implikasi Desain untuk ZenoFit |
| :--- | :---: | :--- |
| **Tidak ada waktu** | **48,7%** | Sesi singkat **3 menit (*Quick Break*)** sebagai *default* (dengan opsi 6–10 menit) di sela *coding/gaming*. |
| **Malas** | **32,6%** | Dikemas sebagai *game* ringan (*Zen Dojo* + *scoring*), langsung dari kursi tanpa ganti baju atau keluar rumah. |
| Lanjut usia | 19,5% | Di luar target primer, tetapi tetap terakomodasi oleh desain duduk inklusif. |
| Tidak ada rekan | 9,8% | Pelatih virtual **ZenoBot** menemani & memandu setiap sesi. |

Total **81,3% alasan teratas (waktu + malas)** dapat langsung dijawab oleh *seated VR active-break game* berdurasi singkat. *(Catatan: laporan ringkas Kemenkes tidak merinci penyebut per kelompok usia — **`[CEK]`** laporan lengkap SKI 2023 untuk usia 15–34 tahun.)*

### 2.3 Profil Spesifik *Desk Workers*, *Gamers*, & Mahasiswa IT
- **Gamer & *Esports*:** **DiFrancisco-Donoghue et al. (2022)** melaporkan pemain *esports* kampus rata-rata hanya menempuh $\pm 6.040\text{ langkah/hari}$ dibanding $\pm 12.844$ pada kontrol seusia (18–25 tahun) dan merekomendasikan menyelingi sesi gaming lama dengan aktivitas fisik singkat. Di Indonesia, survei **APJII 2025** (via Tempo) mencatat **$\pm 54\%$ gamer bermain $\ge 2\text{ jam/hari}$**.
- **Programmer / Pekerja IT:** **Cole et al. (2015)** menunjukkan hambatan utama *software engineer* mengurangi duduk adalah tekanan *"getting the job done"* dan pekerjaan yang mengharuskan duduk lama di depan layar. Analisis O\*NET (NAVO Ergonomics) menempatkan *software developer* pada skor kebutuhan duduk maksimum (100).

### 2.4 Mengapa VR & Mengapa Posisi Duduk (*Seated*)?
- **Preferensi VR bagi Kelompok Kurang Aktif:** **Moffitt (2024)** (*Psychology of Sport and Exercise*) menemukan bahwa orang dengan aktivitas olahraga rendah atau *social physique anxiety* tinggi **lebih memilih olahraga di VR dan di rumah** dibanding gym dunia nyata.
- **Manfaat Aktivitas Singkat (*Exercise Snacks*):** **Stamatakis et al. (2022)** (*Nature Medicine*) menunjukkan 3× aktivitas singkat 1–2 menit/hari pada *non-exerciser* berkaitan dengan penurunan risiko mortalitas 38–40%, sementara **Buffey et al. (2022)** (*Sports Medicine*) menunjukkan jeda duduk dengan aktivitas ringan membantu biomarker kardiometabolik.
- **Efektivitas Latihan Ekstremitas Atas & Faktor *Cybersickness*:** **Flatlandsmo (2023)** & **Wouda et al. (2023)** membuktikan *upper-body VR exergaming* duduk mampu memicu respons aerobik tanpa membebani tungkai bawah, namun **Flatlandsmo (2023)** juga menemukan korelasi negatif sangat kuat ($r = -0{,}817, p < 0{,}00001$) antara *cybersickness* (SSQ) dan *enjoyment* (PACES-S)—menegaskan bahwa **kamera harus stasioner (*zero unintended locomotion*) dengan referensi visual statis**.
- **Tinjauan Kritis Jurnal *Seated iVR* (Xu et al., 2020):** Jurnal [Xu et al. (2020)](./Results%20and%20Guidelines%20From%20a%20Repeated-Measures%20Design%20Experiment%20Comparing%20Standing%20and%20Seated%20Full-Body%20Gesture-Based%20Immersive%20Virtual%20Reality%20Exergames%20-%20Within-Subjects%20Evaluation.pdf) pada $N = 52$ mahasiswa kurang aktif (rata-rata $87{,}9\text{ mnt/mgg}$) membuktikan *seated iVR exergame* dinilai punya ***value/usefulness* lebih tinggi** ($P = .04$) dan ***enjoyment* setara** ($P = .96$) dibanding *standing*, serta menyarankan ***warm-up***, **adaptasi kesulitan**, dan mitigasi ***peripheral/sopite motion sickness*** ($P = .02$ / $P = .004$). Namun, sistem mereka masih membutuhkan **PC VR + 2 *VIVE foot trackers*** karena 5 dari 6 gerakannya mengangkat kaki/lutut. **ZenoFit mengisi *research gap* ini** melalui **standalone VR + *OpenXR Hand Tracking* berbasis *upper-body only*** (tanpa sensor kaki/PC), sehingga angka kalori *full-body* Xu et al. tidak diklaim secara mentah.

---

## 3. Analisis Komparatif: Konvensional vs. VR Komersial vs. ZenoFit

| Parameter | Video / App Layar Datar (YouTube/Mobile) | VR Fitness Komersial (*Beat Saber, FitXR, Supernatural*) | **ZenoFit (*Seated Zen Dojo VR*)** |
| :--- | :--- | :--- | :--- |
| **Keterlibatan (*Adherence*)** | Rendah–sedang: pasif, monoton, tidak merespons gerak pengguna. | Tinggi, tetapi menuntut ruang luas & gerakan berdiri intens. | **Tinggi & ringkas:** sesi 3 menit di kursi dengan *adaptive tempo* & *scoring*. |
| **Aksesibilitas Duduk & Ruang Sempit** | Bisa duduk, tetapi tidak ada registrasi ruang meja. | Kurang ramah duduk (*squat*, *lunge*, *ducking*, rawan bentur meja/kursi). | **Native Seated Upper-Body:** kalibrasi jangkauan $\le 85\%$ + *desk obstacle exclusion*. |
| **Pelacakan & Umpan Balik** | Tidak melacak posisi tangan, pergelangan, atau kepala. | Melacak 3D, umumnya berbasis *controller*. | **3D Spatial Registration** via **OpenXR Hand Tracking** (+ *controller fallback*) + audio/visual spasial Dojo. |
| **Keamanan Postural & *Cybersickness*** | Risiko jatuh rendah, tanpa koreksi tempo/batas aman. | Gerakan menghindar cepat dapat mengganggu keseimbangan duduk. | **Terkontrol:** `Safety Level A/B`, *No-Trunk Mode*, *Auto-Pause* pangkuan + *Passthrough*, *static visual reference* (Zen Dojo). |

---

## 4. Segmentasi Pengguna

```
                      TARGET PENGGUNA ZENOFIT
                                │
         ┌──────────────────────┼──────────────────────┐
         ▼                      ▼                      ▼
   [ PRIMER 1 ]           [ PRIMER 2 ]           [ SEKUNDER ]
  Mahasiswa Gamer /     Developer / Remote     Gym-Shy Beginner &
   IT (18-24 th)           Desk Worker        Keterbatasan Tungkai
```

1. **Primer 1 — Mahasiswa Gamer / IT (18–24 tahun):** Kuliah/laptop + gaming $\ge 2\text{ jam/hari}$; hambatan utama malas, bosan olahraga biasa, ruang kos sempit. Butuh sesi 3 menit seperti *game* di kursi.
2. **Primer 2 — Developer / *Remote Desk Worker*:** Duduk 7–12 jam/hari; hambatan utama *"tidak ada waktu"* dan takut memutus fokus. Butuh *micro-session* tanpa *setup* rumit untuk bahu, leher, punggung, dan pergelangan tangan.
3. **Sekunder (*Curb-Cut Effect*) — Pemula *Gym-Shy* & Pengguna Keterbatasan Tungkai:** Pemula yang minder di gym (Moffitt, 2024) serta pengguna kursi roda atau pemulihan tungkai bawah (Flatlandsmo, 2023; Plavoukou et al., 2025) tetap dapat memakai ZenoFit karena seluruh gerakan dilakukan duduk, mendukung *one-hand mode* dan *No-Trunk mode*.

---

## 5. Temuan Survei Awal Internal (`Jaras Pengguna.csv`, $N = 8$)

Data survei anonim ([Jaras Pengguna.csv](./Jaras%20Pengguna.csv), 10–11 Nov 2026) digunakan sebagai **arah desain awal** (sampel kecil, perlu diperluas ke $N \ge 30$):
- **Durasi duduk:** 7 dari 8 responden duduk **8–12+ jam/hari**.
- **Area keluhan utama:** Leher & bahu/pundak, punggung bawah, pergelangan tangan (anti-RSI), dan mata lelah; 2–4 responden tidak punya keluhan nyeri (**kebutuhan bersifat preventif**).
- **Hambatan:** Lupa jeda, takut mengganggu *workflow*, malas berkeringat, ruang meja sempit, serta kekhawatiran *setup* VR (R5), *motion sickness* (R6), dan skeptisisme istirahat mata di VR (R7).
- **Fitur yang diinginkan:** *Hand tracking* tanpa *controller*, *light gamification*, *passthrough*, dan audio tenang (*lofi/zen*).
- **Ketertarikan:** Rata-rata **3,88 / 5** (6 dari 8 memberi nilai 4–5).

---

## 6. Katalog Gerakan Duduk Aman & Pemetaan ke *Zen Dojo Mechanics*

### 6.1 Asal-Usul Gerakan Aman (Irisan Riset Awal & Referensi PDF)
Dari 10 gerakan duduk aman awal (mobilitas, kardio ringan, kontrol otot) serta referensi latihan duduk ([Exercise Analysis/](../Exercise%20Analysis/)), gerakan disaring agar **100% *upper-body***, bebas benturan meja, dan akurat dilacak sensor VR:
- **Diadopsi langsung (5):** *Seated Boxing* (`M01`), *Side Arm Raise* (`M03`), *Seated Row* (`M05`), *Forward Press* (`M06`), *Seated Biceps Curl + Elbow Flexion* (`M09` + tambahan *wrist pour* anti-RSI).
- **Dimodifikasi karena pelacakan VR (2):** *Shoulder Rolls* diganti *Arm Circles* (`M07`, karena bahu tidak terlacak saat tangan diam); *Forward/Alternating Reach* dinaikkan jadi *Diagonal Overhead Reach* (`M02`, anti-bungkuk).
- **Ditinggalkan (1):** *Seated Swimming Motion*.
- **Ditambahkan pasca-survei & segmentasi 3 *Routine* (6):** *Trunk Twist* (`M04`), *Neck Mobility* (`M08`), *Overhead Reach + Side Bend* (`M10`), *Cactus Arms / Chest Opener* (`M11`), *Seated Spinal Flex / Cat–Cow* (`M12`), dan *Wrist Rolls* (`M13`).

### 6.2 Segmentasi 3 *Routine* & 13 Mekanik (*Zen Dojo Theme*)

| *Routine* (Durasi: `3 min` default · `6–10 min` opsional) | Mekanik Termasuk (`M01`–`M13`) | Catatan Keamanan |
| :--- | :--- | :--- |
| **1. Full Upper-Body Reset** | Campuran seimbang dari seluruh 13 mekanik | `Level B` tidak pernah berurutan; mencakup semua grup tubuh. |
| **2. Arms & Shoulders** | `M01` **Makiwara Strikes** (*Boxing*), `M02` **Sakura Catch** (*Overhead Reach*), `M03` **Crane Wings** (*Side Raise*), `M06` **Ki Palm Push** (*Forward Press*), `M07` **Zen Water Wheel** (*Arm Circles*), `M09` **Tea Ceremony Pour** (*Curl + Wrist Pour*), `M13` **Ink Spiral** (*Wrist Rolls*) | **100% `Level A`** — aman di semua jenis kursi (termasuk kursi putar/roda). |
| **3. Back & Posture** | `M05` **Temple Bell Pull** (*Seated Row*, `Lvl A`), `M11` **Dojo Gate Opener** (*Cactus Arms*, `Lvl A`), `M04` **Bokken Guard** (*Trunk Twist*, `Lvl B`), `M08` **Zen Horizon Watch** (*Neck Mobility*, `Lvl B`), `M10` **Bamboo Sway** (*Side Bend*, `Lvl B`), `M12` **Rei Breath** (*Spinal Flex*, `Lvl B`) | Mekanik `Level B` membutuhkan kursi stabil; jika *No-Trunk Mode* aktif, otomatis melengkapi dari bahu anti-bungkuk (`M02, M03, M07`). |

### 6.3 Pedoman Keselamatan & Desain Interaksi Duduk
- **Batas Jangkauan ($\le 85\%$):** Seluruh target muncul di dalam $\le 85\%$ jangkauan kalibrasi masing-masing tangan (setinggi tulang dada/*sternum* untuk gerak depan; *scapular plane* $15^\circ\text{–}30^\circ$ ke depan untuk `M03` & `M11` agar aman bagi bahu sekaligus tetap dalam FoV kamera *hand tracking*).
- **Mode Satu Tangan & Bebas Penalti Tubuh Bawah:** Mendukung `Both Hands`, `Left Only`, dan `Right Only`; skor hanya bergantung pada akurasi, ritme, dan kelancaran gerak tubuh atas.
- **Fail-Safe & Pengingat Leher:** Menurunkan kedua tangan ke pangkuan selama `2,0 s` otomatis memicu **Auto-Pause + Passthrough**; jeda istirahat leher setiap 7–10 menit (wajib pada sesi Extended 10 menit); *Lean Warning* bila condong berlebihan.
- **Non-Medical Disclaimer:** ZenoFit adalah aplikasi *active-break* preventif, **bukan perangkat rehabilitasi medis**.
- **Desain UI/UX (Figma):** [Link Figma Desain Gameplay](https://www.figma.com/design/y3Qk2DL1iYYFwcp0Lmq8da/Untitled?node-id=0-1&t=t7dM1qQXo11I3vod-1)

---

## 7. Keterbatasan, Kejujuran Ilmiah, & Rencana Validasi Lanjutan

1. **Hindari stereotip *"gamer pasti tidak sehat"*:** Meta-analisis **Marker, Gnambs & Appel (2022)** ($N = 38.097$) menemukan korelasi gaming dan berat badan sangat kecil. Argumen ZenoFit adalah **durasi duduk panjang dan hambatan praktis berolahraga di luar**, bukan stereotip fisik.
2. **Intensitas jujur (ringan–sedang):** Angka 7–8 METs (*Supernatural* berdiri) dan kalori *full-body seated* (Xu et al., 2020) **tidak berlaku** untuk ZenoFit. Tujuannya memutus duduk lama dan menjaga mobilitas tubuh atas.
3. **Hambatan kepemilikan headset & *setup friction*:** Target paling realistis adalah pengguna yang sudah memiliki akses headset (pribadi/lab/komunitas), dengan fokus menurunkan *setup friction* lewat **OpenXR Hand Tracking** dan *Quick Seat Check* $\le 10\text{ detik}$.
4. **Rencana Validasi Primer ($N \ge 30\text{–}50$ responden):** Memperluas survei ke mahasiswa & pekerja IT di luar lingkaran dekat untuk memvalidasi durasi sesi ideal, kepemilikan VR, dan minat *active break*, diikuti pengujian langsung di **PICO 4 Ultra / Meta Quest** (mengukur *task completion*, *IMI*, dan *MSAQ/SSQ*).

---

## 8. Daftar Pustaka

- Bull, F. C., et al. (2020). World Health Organization 2020 guidelines on physical activity and sedentary behaviour. *British Journal of Sports Medicine, 54*(24), 1451–1462.
- Buffey, A. J., Herring, M. P., Langley, C. K., Donnelly, A. E., & Carson, B. P. (2022). The acute effects of interrupting prolonged sitting time in adults with standing and light-intensity walking on biomarkers of cardiometabolic health. *Sports Medicine, 52*, 1765–1787. https://doi.org/10.1007/s40279-022-01649-4
- Cole, J. A., Tully, M. A., & Cupples, M. E. (2015). "They should stay at their desk until the work's done": A qualitative study examining perceptions of sedentary behaviour in a desk-based occupational setting. *BMC Research Notes, 8*, 683.
- DiFrancisco-Donoghue, J., Werner, W. G., Douris, P. C., & Zwibel, H. (2022). Esports players, got muscle? Competitive video game players' physical activity, body fat, bone mineral content, and muscle mass. *Journal of Sport and Health Science, 11*(6), 725–730.
- Flatlandsmo, E. (2023). *Novel VR exergaming for wheelchair users: Cybersickness and user experience*. NTNU. https://hdl.handle.net/11250/3090583
- Kementerian Kesehatan RI, BKPK. (2025). *Kurang Bergerak, Ancaman Tersembunyi Kesehatan Indonesia* (Data SKI 2023).
- Marker, C., Gnambs, T., & Appel, M. (2022). Exploring the myth of the chubby gamer: A meta-analysis on sedentary video gaming and body mass. *Social Science & Medicine, 301*, 112325. **`[CEK volume]`**
- Moffitt, R. (2024). A psychosocial investigation of exercise preferences in real and virtual environments. *Psychology of Sport and Exercise*. **`[CEK penulis lengkap & volume]`**
- Plavoukou, T., Apostolakopoulou, K., Papagiannis, G., Stasinopoulos, D., & Georgoudis, G. (2025). Impact of virtual reality, augmented reality, and sensor technology in knee osteoarthritis rehabilitation: A systematic review. *Cureus, 17*(2), e79011. https://doi.org/10.7759/cureus.79011
- Stamatakis, E., et al. (2022). Association of wearable device-measured vigorous intermittent lifestyle physical activity with mortality. *Nature Medicine, 28*, 2521–2529. https://doi.org/10.1038/s41591-022-02100-x
- Strain, T., et al. (2024). National, regional, and global trends in insufficient physical activity among adults from 2000 to 2022. *The Lancet Global Health, 12*(8), e1232–e1243.
- Tempo. (2025). *These are the most-played online games in Indonesia* (Data APJII 2025).
- WHO. (2024). *Nearly 1.8 billion adults at risk of disease from not doing enough physical activity.*
- Xu, W., Liang, H.-N., He, Q., Li, X., Yu, K., & Chen, Y. (2020). Results and guidelines from a repeated-measures design experiment comparing standing and seated full-body gesture-based immersive virtual reality exergames: Within-subjects evaluation. *JMIR Serious Games, 8*(3), e17972. https://doi.org/10.2196/17972
