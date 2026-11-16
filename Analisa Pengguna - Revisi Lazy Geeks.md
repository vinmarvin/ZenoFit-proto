# Analisa Pengguna (Revisi) — Target: "Lazy Couch Geeks"

> Pengganti Bagian 1–3 di "Virtual Fitness App for Lazy Couch Geeks.md".
> Gerakan (5 gerakan duduk, upper-body) **tidak berubah**; yang berubah adalah *siapa* penggunanya dan *mengapa* mereka butuh aplikasi ini.
> Tanda **[CEK]** = angka/penulis yang belum kami baca dari paper aslinya. Cek dulu sebelum dikumpulkan.

---

## 0. Definisi Operasional "Lazy Geek"

Kata "malas" tidak bisa diukur, jadi kami definisikan target secara terukur:

> **Orang dewasa muda (±18–35 tahun) yang menghabiskan banyak waktu duduk di depan layar (gaming, coding, kuliah/kerja di laptop), aktivitas fisiknya di bawah rekomendasi WHO, dan *tidak mau atau tidak sempat* pergi ke gym atau berolahraga di luar rumah.**

Tiga kriteria yang bisa dicek lewat kuesioner:
1. **Screen-heavy**: duduk/di depan layar ≥ 6 jam per hari (di luar tidur).
2. **Insufficiently active**: < 150 menit aktivitas sedang per minggu (standar WHO).
3. **Indoor-preference**: alasan tidak berolahraga adalah malas, tidak ada waktu, atau tidak nyaman di gym/tempat umum.

---

## 1. Masalahnya Besar dan Makin Parah

| Fakta | Sumber |
| :--- | :--- |
| **31% orang dewasa di dunia (±1,8 miliar)** tidak cukup aktif pada 2022. Angkanya naik dari 26% (2010) dan diproyeksikan **35% pada 2030**. Wilayah *high-income Asia Pacific* tertinggi (48%). | WHO (26 Juni 2024); Strain et al. (2024), *The Lancet Global Health* |
| Di Indonesia, **37,4% penduduk usia ≥10 tahun kurang aktivitas fisik**. Angkanya naik dari 33,5% (Riskesdas 2018) dan 26,1% (2013). | Survei Kesehatan Indonesia (SKI) 2023, via BKPK Kemenkes |
| WHO 2020: *"some physical activity is better than none"*. Waktu duduk sebaiknya diganti dengan aktivitas **intensitas apa pun, termasuk ringan**. | Bull et al. (2020), *British Journal of Sports Medicine* — WHO Guidelines |

**Implikasi desain:** aplikasi tidak harus menggantikan gym. Cukup memindahkan pengguna dari "nol aktivitas" ke "ada aktivitas". Klaim ini didukung langsung oleh pedoman WHO.

---

## 2. Bukti Utama: "Malas" Benar-Benar Ada di Data Nasional

Ini argumen terkuat untuk dosen. **"Malas" bukan asumsi kami; ia muncul di data resmi pemerintah.**

Menurut SKI 2023, alasan penduduk Indonesia kurang aktivitas fisik adalah:

| Alasan | Persentase | Relevansi untuk desain aplikasi |
| :--- | :---: | :--- |
| Tidak ada waktu | **48,7%** | Sesi pendek 5–10 menit, bisa disisipkan di antara game/coding |
| **Malas** | **32,6%** | Dikemas sebagai *game*, bukan "olahraga"; tidak perlu keluar rumah atau ganti baju |
| Lanjut usia | 19,5% | (di luar target utama) |
| Tidak ada rekan | 9,8% | Bisa dijawab di masa depan dengan *leaderboard* atau *co-op* |

Jadi **81,3% alasan teratas (waktu + malas)** adalah hambatan yang bisa dijawab oleh *exergame* duduk yang singkat di rumah.

> Catatan: halaman Kemenkes tidak menyebutkan penyebut (denominator) persentase ini dan tidak memberi rincian per usia atau pekerjaan. **[CEK]** laporan SKI 2023 lengkap untuk kelompok usia 15–24 dan 25–34.

---

## 3. Mengapa "Geek" Secara Spesifik? (Gamer, Programmer, Mahasiswa IT)

### 3.1 Gamer / pemain esports bergerak jauh lebih sedikit
- **DiFrancisco-Donoghue et al. (2022)**: pemain esports kampus rata-rata hanya **±6.040 langkah per hari**, dibandingkan **±12.844 langkah** pada kontrol seusia (18–25 tahun). Body fat mereka lebih tinggi dan massa otot serta tulang lebih rendah, **walaupun BMI-nya sama**. (Sampel kecil: 24 laki-laki.)
- Penulis yang sama (BMJ Open Sport & Exercise Medicine, 2021 dan 2024) **merekomendasikan agar sesi gaming yang lama diselingi aktivitas fisik singkat**. Rekomendasi ini persis menggambarkan konsep aplikasi kita.

### 3.2 Gamer Indonesia bermain lama
- Survei **APJII 2025** (via Tempo): **±54% gamer Indonesia bermain ≥ 2 jam per hari** (30,30% bermain 2–3 jam, 15,80% bermain 3–4 jam, 8,05% bermain > 4 jam).
- Jumlah gamer Indonesia diperkirakan **>126 juta** (Niko Partners). Estimasi lembaga lain bervariasi, sampai 150 juta lebih.

### 3.3 Programmer / pekerja IT adalah pekerjaan paling banyak duduk
- Analisis data O*NET (NAVO Ergonomics): **software developer mendapat skor "sitting requirement" maksimum (100)** dari 18 pekerjaan yang dibandingkan. *(Sumber industri, bobot bukti rendah.)*
- Studi cross-sectional 2026 pada 235 pekerja IT di Wuhan: rata-rata **±7,1 jam per hari duduk saat bekerja** dan **±8,3 jam per hari total**, dan total waktu duduk berhubungan dengan stres. **[CEK penulis & jurnal]**
- Cole et al. (2015), studi kualitatif pada software engineer: hambatan utama mengurangi duduk adalah tekanan *"getting the job done"* dan kerja yang memang mengharuskan duduk di depan komputer.

### 3.4 Mahasiswa Indonesia
- Beberapa studi lokal melaporkan mayoritas mahasiswa berada di kategori aktivitas fisik rendah (salah satunya 85%) dan *screen time* tinggi. *(Studi kecil, cross-sectional, kualitas jurnal bervariasi. Pakai sebagai pendukung, bukan bukti utama.)*

---

## 4. Mengapa Mereka Tidak Ke Gym, dan Mengapa VR Cocok

- **Moffitt (2024), *Psychology of Sport and Exercise*** (3 studi): orang yang **aktivitas olahraganya rendah**, sering membandingkan fisiknya dengan orang lain secara negatif, atau punya **social physique anxiety** tinggi **lebih memilih olahraga di VR daripada olahraga di dunia nyata**. Mereka juga lebih memilih latihan di rumah daripada di gym.
  → Ini bukti langsung bahwa **orang yang paling malas dan paling minder justru kelompok yang paling tertarik pada VR fitness.** Profil ini sama dengan target kita.
- Riset tentang *gym anxiety* (Frontiers in Sports and Active Living, 2026) menunjukkan rasa tidak nyaman di gym adalah hambatan nyata yang terpisah dari kecemasan sosial umum.

---

## 5. Apakah Gerakan Duduk Ringan Ada Manfaatnya? (Menjawab "Kenapa Bukan Olahraga Biasa?")

| Bukti | Makna untuk aplikasi |
| :--- | :--- |
| **Stamatakis et al. (2022), *Nature Medicine***: pada 25.241 **non-exerciser** (orang yang tidak pernah berolahraga), ±3 kali aktivitas berat singkat (1–2 menit) per hari berasosiasi dengan risiko kematian **38–40% lebih rendah**. Penulis menyebut pendekatan ini cocok untuk orang yang *"unable or unwilling to exercise"*. | Dosis kecil yang tersebar dalam sehari itu berarti. Sesi Seated Boxing intensitas tinggi selama 2 menit bisa diposisikan sebagai "exercise snack". *(Studi observasional, peserta rata-rata usia 62 tahun.)* |
| **Buffey et al. (2022), *Sports Medicine*** (meta-analisis): menyelingi duduk lama dengan aktivitas ringan menurunkan glukosa (dan insulin) setelah makan. | Mendukung konsep "break" di sela-sela gaming atau coding. *(Studi yang dianalisis memakai jalan kaki/berdiri, bukan gerakan lengan duduk. Lihat Bagian 7.)* |
| **Craig, Rhodes & Sui (2024), *JMIR Serious Games***: VR fitness (Supernatural) mencapai **7,6–8,2 METs** (intensitas berat) pada dewasa muda. | VR terbukti bisa menjadi olahraga sungguhan, bukan sekadar mainan. *(Didanai Supernatural; gerakannya berdiri, jadi intensitasnya lebih tinggi daripada versi duduk kita.)* |
| Meta-analisis 2022: intervensi *active video game* **meningkatkan aktivitas fisik secara moderat**. Studi lab menunjukkan VR terasa **lebih menyenangkan dan lebih tidak melelahkan** dibanding latihan konvensional. | Gamifikasi membantu mengatasi faktor "malas". |

---

## 6. Segmentasi Pengguna (Baru)

```
                       TARGET PENGGUNA
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
  [ PRIMER 1 ]         [ PRIMER 2 ]         [ SEKUNDER ]
  Mahasiswa Gamer      Developer / WFH      Gym-shy Beginner &
  (18–24 th)           Desk Worker          Keterbatasan Tungkai
```

### 6.1 Primer 1 — Mahasiswa Gamer (contoh: mahasiswa Informatika)
- **Kebiasaan**: kuliah daring/laptop + gaming ≥ 2 jam per hari, jarang berolahraga.
- **Hambatan**: malas, merasa olahraga itu membosankan, tidak mau keluar kos.
- **Kebutuhan**: terasa seperti *game* (skor, ritme, combo), sesi 5–10 menit, bisa dimainkan sambil tetap duduk di kursi gaming.
- **Bukti**: SKI 2023 (malas 32,6%), APJII 2025, DiFrancisco-Donoghue (2022).

### 6.2 Primer 2 — Developer / Remote Worker
- **Kebiasaan**: duduk 7–8+ jam per hari, fokus deadline.
- **Hambatan**: "tidak ada waktu" (48,7%), tidak mau memutus *flow* kerja terlalu lama.
- **Kebutuhan**: *micro-session* 2–5 menit sebagai *break*, tanpa setup, langsung main dari kursi kerja.
- **Bukti**: O*NET/NAVO, Cole et al. (2015), Buffey et al. (2022), Stamatakis et al. (2022).

### 6.3 Sekunder — Gym-shy Beginner & Pengguna dengan Keterbatasan Tungkai
- Pemula yang minder atau tidak nyaman di gym (Moffitt, 2024).
- Pengguna dengan keterbatasan tubuh bagian bawah (riset lama tim: Flatlandsmo 2023, Plavoukou 2025) tetap bisa memakai aplikasi karena semua gerakan dilakukan sambil duduk. Ini adalah **manfaat tambahan dari desain inklusif** (*curb-cut effect*), bukan target utama lagi.

---

## 7. Keterbatasan & Bukti yang Bertentangan (Wajib Disebut: Dosen Menghargai Kejujuran)

1. **Stereotip "gamer pasti tidak sehat" lemah.** Meta-analisis **Marker, Gnambs & Appel** (*"Exploring the myth of the chubby gamer"*, 38.097 peserta) menemukan hubungan gaming dengan berat badan **sangat kecil** dan bukti bahwa gaming "menggusur" olahraga juga tipis.
   → Karena itu argumen kita **bukan "gamer itu gemuk"**, tetapi **"gamer dan pekerja IT duduk sangat lama dan punya hambatan nyata untuk berolahraga di luar"**.
2. **Gerakan lengan sambil duduk intensitasnya lebih rendah** daripada VR fitness berdiri. Angka 7–8 METs dari Supernatural **tidak berlaku** untuk aplikasi kita. Klaim yang jujur: *ringan sampai sedang*, tujuannya **memutus duduk lama dan membangun kebiasaan**, bukan menggantikan latihan kardio penuh.
3. Banyak bukti berasal dari sampel kecil, studi observasional, atau populasi lain (lansia, orang Barat). Validasi langsung dengan target lokal tetap diperlukan (lihat Bagian 8).
4. Hambatan akses: headset VR masih mahal, jadi target realistisnya adalah orang yang **sudah punya headset** atau punya akses (lab kampus, komunitas VR).

---

## 8. Validasi Primer (Rekomendasi: Bukti Paling Kuat untuk Dosen)

Sumber sekunder di atas membuktikan masalahnya ada. **Bukti bahwa target kita benar-benar ada di sekitar kita** harus datang dari data sendiri. Usulan: Google Form, minimal **30–50 responden** mahasiswa ITS / komunitas gamer.

| # | Pertanyaan | Tujuan |
| :-: | :--- | :--- |
| 1 | Rata-rata berapa jam per hari kamu duduk di depan layar (kuliah, kerja, game)? | Kriteria *screen-heavy* |
| 2 | Berapa hari per minggu kamu berolahraga minimal 30 menit? | Kriteria *insufficiently active* (versi singkat IPAQ/GPAQ) |
| 3 | Alasan utama kamu jarang berolahraga? (tidak ada waktu / malas / tidak nyaman di gym / tidak ada teman / lainnya) | Membandingkan hasil dengan SKI 2023 |
| 4 | Berapa jam per hari kamu bermain game? Di platform apa? | Profil gamer |
| 5 | Apakah kamu pernah mencoba atau punya akses ke headset VR? | Kelayakan pasar |
| 6 | Seberapa tertarik kamu mencoba "game olahraga 5 menit sambil duduk"? (skala 1–5) | Minat langsung |
| 7 | Berapa lama sesi ideal menurutmu? (2 / 5 / 10 / 15+ menit) | Desain durasi sesi |

**Contoh kalimat untuk laporan:** *"Dari N responden, X% duduk di depan layar ≥ 6 jam per hari, Y% berolahraga < 3 hari per minggu, dan alasan terbanyak adalah ... (sejalan dengan SKI 2023)."*

---

## Daftar Pustaka

- Bull, F. C., et al. (2020). World Health Organization 2020 guidelines on physical activity and sedentary behaviour. *British Journal of Sports Medicine, 54*(24), 1451–1462.
- Buffey, A. J., Herring, M. P., Langley, C. K., Donnelly, A. E., & Carson, B. P. (2022). The acute effects of interrupting prolonged sitting time in adults with standing and light-intensity walking on biomarkers of cardiometabolic health: A systematic review and meta-analysis. *Sports Medicine, 52*, 1765–1787. https://doi.org/10.1007/s40279-022-01649-4
- Cole, J. A., Tully, M. A., & Cupples, M. E. (2015). "They should stay at their desk until the work's done": A qualitative study examining perceptions of sedentary behaviour in a desk-based occupational setting. *BMC Research Notes, 8*, 683. https://doi.org/10.1186/s13104-015-1670-2
- Craig, T. V., Rhodes, R. E., & Sui, W. (2024). Energy expenditure of the Supernatural VR fitness game. *JMIR Serious Games, 12*, e53999. https://games.jmir.org/2024/1/e53999 **[CEK judul persis]**
- DiFrancisco-Donoghue, J., Werner, W. G., Douris, P. C., & Zwibel, H. (2022). Esports players, got muscle? Competitive video game players' physical activity, body fat, bone mineral content, and muscle mass in comparison to matched controls. *Journal of Sport and Health Science, 11*(6), 725–730. https://pmc.ncbi.nlm.nih.gov/articles/PMC9729923
- Kementerian Kesehatan RI, BKPK. (2025, 4 November). *Kurang Bergerak, Ancaman Tersembunyi Kesehatan Indonesia* (data SKI 2023). https://www.badankebijakan.kemkes.go.id/kurang-bergerak-ancaman-tersembunyi-kesehatan-indonesia/
- Marker, C., Gnambs, T., & Appel, M. (2022). Exploring the myth of the chubby gamer: A meta-analysis on sedentary video gaming and body mass. *Social Science & Medicine, 301*, 112325. https://pubmed.ncbi.nlm.nih.gov/31262505 **[CEK volume]**
- Moffitt, R. (2024). A psychosocial investigation of exercise preferences in real and virtual environments. *Psychology of Sport and Exercise*. https://research-repository.griffith.edu.au/items/06eccb80-d81f-40ac-9b65-cdae26dd1d6f **[CEK penulis lain & volume]**
- Stamatakis, E., et al. (2022). Association of wearable device-measured vigorous intermittent lifestyle physical activity with mortality. *Nature Medicine, 28*, 2521–2529. https://doi.org/10.1038/s41591-022-02100-x
- Strain, T., et al. (2024). National, regional, and global trends in insufficient physical activity among adults from 2000 to 2022: A pooled analysis of 507 population-based surveys with 5.7 million participants. *The Lancet Global Health, 12*(8), e1232–e1243.
- Tempo. (2025). *These are the most-played online games in Indonesia* (data APJII 2025). https://en.tempo.co/read/2038684/these-are-the-most-played-online-games-in-indonesia
- WHO. (2024, 26 Juni). *Nearly 1.8 billion adults at risk of disease from not doing enough physical activity.* https://www.who.int/news/item/26-06-2024-nearly-1.8-billion-adults-at-risk-of-disease-from-not-doing-enough-physical-activity
- Tetap dipakai dari riset sebelumnya (untuk segmen sekunder): Flatlandsmo (2023); Plavoukou et al. (2025).
