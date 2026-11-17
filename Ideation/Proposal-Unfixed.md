Riset pengguna (Ryan) :

# Analisa Pengguna

## **1\. Latar Belakang & Analisis Komparatif Aplikasi Kebugaran Konvensional**

### **1.1 Konteks Masalah**

Aktivitas fisik teratur merupakan pilar utama kesehatan mental dan kardiovaskular. Namun, data epidemiologi menunjukkan bahwa penyandang disabilitas fisik atau keterbatasan mobilitas tubuh bagian bawah mengalami tingkat inaktivitas fisik **3 hingga 5 kali lebih tinggi** dibandingkan populasi umum (Rimmer et al., 2004; Flatlandsmo, 2023). Inaktivitas jangka panjang memicu lingkaran setan (*vicious cycle*): atrofi otot, kekakuan sendi, obesitas, sindrom metabolik, hingga depresi.

Mayoritas ekosistem kebugaran komersial saat ini didesain dengan bias kuat terhadap populasi bertubuh sehat (*able-bodied*), yang secara inheren mengasumsikan kemampuan berdiri, melompat, dan menopang beban tungkai bawah (*weight-bearing capacity*).

### **1.2 Analisis Komparatif: Media Konvensional vs. VR Kebugaran Seated**

| Parameter Evaluasi | Aplikasi Kebugaran Layar Datar (Mobile/Tablet/TV/YouTube) | Aplikasi VR Kebugaran Komersial Saat Ini (Beat Saber, FitXR, Supernatural) | Proposed Accessible Seated VR Fitness App |
| :---- | :---- | :---- | :---- |
| **Keterlibatan & Motivasi (*Adherence*)** | **Rendah \- Sedang**: Monoton, pasif, angka *drop-out* tinggi karena minim stimulasi interaktif. | **Tinggi**: Sangat menghibur, namun sering memicu frustrasi bagi pengguna dengan keterbatasan mobilitas. | **Tinggi & Terarah**: Dirancang khusus dengan *flow state* adaptif tanpa diskriminasi mekanik. |
| **Aksesibilitas Posisi Duduk (*Seated Mode*)** | **Parsial**: Gerakan latihan duduk sering kali hanya berupa adaptasi seadanya dari senam lansia. | **Kurang Ramah**: Sering memaksakan *squat*, *lunge*, *ducking*, atau *knee strike*; kalibrasi tinggi lantai (*Y-offset*) rumit. | **Prioritas Utama (Native)**: Seluruh interaksi, jangkauan target, dan navigasi dioptimalkan dari kursi. |
| **Umpan Balik Sensori (*Feedback*)** | **Visual 2D**: Pengguna harus terus menoleh ke layar; tidak ada sensasi kontak fisik. | **Haptik 3D Penuh**: *Controller rumble* memberikan sensasi impak virtual. | **Haptik Terkalibrasi**: Haptik adaptif yang disesuaikan dengan sensitivitas tangan dan batas stabilitas tubuh. |
| **Keamanan Postural & Biomekanika** | **Netral**: Risiko jatuh rendah, namun minim panduan koreksi postur *real-time*. | **Beresiko**: Gerakan menghindar cepat dapat membuat pengguna kursi roda kehilangan keseimbangan. | **Aman & Terkontrol**: Batas jangkauan (*reach envelope*) ergonomis, mencegah nyeri bahu (*impingement*). |

## **2\. Landasan Empiris dan Opini Nyata Pengguna**

Pengembangan aplikasi *seated VR fitness* berbasis tubuh bagian atas (*upper body*) didukung oleh landasan riset saintifik dan laporan pengalaman langsung dari pengguna di komunitas.

### **2.1 Landasan Ilmiah (Fakta Empiris)**

1. **Efektivitas VR dalam Menurunkan Persepsi Nyeri & Meningkatkan Kepatuhan**  
   Berdasarkan tinjauan sistematis terhadap *Randomized Controlled Trials* (RCT) oleh **Plavoukou et al. (2025)** pada pasien rehabilitasi sendi ekstremitas bawah (*Knee Osteoarthritis*), integrasi VR dan sensor secara signifikan meningkatkan kepatuhan latihan serta menurunkan persepsi nyeri (*Visual Analog Scale* / VAS dan skor WOMAC). VR bekerja melalui mekanisme distraksi imersif (*immersive distraction*), yang mengalihkan perhatian otak dari sinyal nosiseptif (nyeri) dan kecemasan gerak (*kinesiophobia*), sehingga pasien dapat berolahraga lebih lama dengan rasa nyaman.  
2. **Kapasitas Latihan Kardiovaskular Melalui Ekstremitas Atas**  
   Penelitian **Flatlandsmo (2023)** di NTNU serta riset **Wouda et al. (2023)** membuktikan bahwa *exergaming* tubuh bagian atas mampu memicu respons kardiovaskular hingga zona aerobik moderat (75% \- 86% dari denyut jantung puncak). Denyut jantung puncak untuk latihan tubuh bagian atas dihitung menggunakan estimasi Hill et al.:

3. $H{R}_{peak}=220-usia-20$  
4. Hal ini membuktikan bahwa latihan berbasis duduk tetap efektif menjaga kebugaran kardio tanpa membebani tungkai bawah.  
5. **Korelasi Kritis Cybersickness dan Kesenangan (*Enjoyment*)**  
   Studi Flatlandsmo (2023) menunjukkan korelasi negatif yang sangat kuat ($r=-0.817,p<0.00001$) antara skor mabuk simulator (*Simulator Sickness Questionnaire* / SSQ) dan kenikmatan berolahraga (*Short Physical Activity Enjoyment Scale* / PACES-S). Artinya, **setiap disorientasi visual pada mode duduk langsung menghancurkan motivasi pengguna**. Oleh karena itu, latihan stasioner tubuh bagian atas (seperti *Seated Boxing* dan *Arm Reach*) jauh lebih unggul dan aman dibandingkan simulator navigasi bebas yang memicu disorientasi spasial.

### **2.2 Suara Pengguna & Komunitas Nyata (Opini Lapangan)**

1. **David Ryan [(*Old Cynic* \- Meta Quest Seated Workout Experience):](https://oldcynic.com/meta-quest-2-vr-seated-workout-limited-mobility)**  
   *Pengalaman pemulihan cedera kaki parah, kursi roda, dan kruk:*  
   *"Duduk di kursi dan meninju udara kosong di ruang tamu akan terasa membosankan dengan sangat cepat. Di situlah kehebatan VR hadir... Anda berada di ring tinju virtual, dengan sensasi nyata dari getaran controller saat mengenai sasaran. Latihan menjadi nyata, bukan lagi sekadar menggerakkan tangan tanpa tujuan."*  
   *Catatan Kritis David:* Pengguna duduk sangat rentan membentur sandaran tangan kursi (*armrests*). Game komersial sering gagal mendeteksi tinggi duduk secara otomatis sehingga pengguna harus mengotak-atik pengaturan *Floor Y-Offset* di menu pengembang.  
2. **Diskusi Forum Komunitas Meta ([Anyone with a physical disability using Quest for exercise?](https://communityforums.atmeta.com/games-apps-13/anyone-with-a-physical-disability-using-quest-for-exercise-180075)):**  
   * Pengguna dengan *Cerebral Palsy* dan keterbatasan mobilitas menyoroti kekecewaan mereka terhadap game fitness populer yang memotong skor jika pemain tidak melakukan *squat* atau *lunge*.  
   * Anggota komunitas (*Choleni & kojack*) menekankan bahaya disorientasi postural: *"Jika game di VR menampilkan gerakan membelok tajam sementara tubuh kita duduk di kursi statis, otak secara refleks mencoba memiringkan tubuh untuk menyeimbangkan diri. Ini bisa membuat pengguna terjatuh dari kursi roda atau tempat duduknya."*

## **3\. Segmentasi Pengguna (Target Personas & Rationale)**

Berdasarkan sintesis data klinis dan dinamika komunitas, audiens terbagi menjadi tiga segmen utama:

                         TARGET PENGGUNA

                                 │

         ┌───────────────────────┼───────────────────────┐

         ▼                       ▼                       ▼

   \[ SEGMEN 1 \]             \[ SEGMEN 2 \]            \[ SEGMEN 3 \]

 Pengguna Kursi Roda      Pemulihan Medis,       Fisioterapis & Pelatih

 Aktif & Permanen         Lansia & Sendi            Adaptif Klinis

### **3.1 Segmen 1: Pengguna Kursi Roda Aktif & Permanen (Wheelchair Users)**

* **Karakteristik**: Penyandang cedera saraf tulang belakang (*Spinal Cord Injury* / SCI paraplegia), spina bifida, atau amputasi tungkai bawah yang menggunakan kursi roda manual atau elektrik sehari-hari.  
* **Alasan Menggunakan VR Fitness**:  
  * Membutuhkan sarana kardio mandiri di dalam ruangan tanpa tergantung cuaca atau aksesibilitas trotoar/gym.  
  * Menginginkan tantangan olahraga yang intensif namun aman dari bahaya terjatuh.  
* **Bukti Penguat**: Riset Wouda et al. (2023) dan Flatlandsmo (2023) menegaskan bahwa penyandang SCI membutuhkan sarana latihan kardio *upper-body* teratur untuk mencegah penyakit metabolik akibat gaya hidup sedentari.

### **3.2 Segmen 2: Pasien Pemulihan Medis, Gangguan Sendi, & Lansia**

* **Karakteristik**: Individu dengan *Knee/Hip Osteoarthritis*, masa pasca-operasi ligamen/sendi kaki, obesitas ekstrem, atau lansia dengan kelemahan muskuloskeletal (*frail elderly*).  
* **Alasan Menggunakan VR Fitness**:  
  * Mengalami *weight-bearing intolerance* (lutut/kaki tidak mampu menahan beban tubuh saat berdiri).  
  * Mengalami *kinesiophobia* (takut bergerak karena trauma rasa sakit).  
  * Butuh pemeliharaan mobilitas bahu, kelenturan toraks, dan sirkulasi darah tanpa membebani lutut/panggul.  
* **Bukti Penguat**: Plavoukou et al. (2025) menunjukkan bahwa teknologi interaktif virtual efektif menurunkan skor disabilitas KOOS/WOMAC dan meningkatkan rasa percaya diri (*self-efficacy*) pasien gangguan sendi bawah. Pengalaman David Ryan (*Old Cynic*) membuktikan transisi dari kursi roda menuju pemulihan terbantu oleh latihan kardio duduk di Meta Quest.

### **3.3 Segmen 3: Fisioterapis & Pelatih Kebugaran Adaptif (Clinical Stakeholders)**

* **Karakteristik**: Tenaga kesehatan profesional, terapis okupasi, atau pelatih kebugaran disabilitas yang merancang dan memantau program latihan klien.  
* **Alasan Menggunakan VR Fitness**:  
  * Membutuhkan alat terapi yang mampu meningkatkan kepatuhan pasien di rumah (*telerehabilitation*).  
  * Membutuhkan metrik objektif (*Range of Motion*, repetisi, durasi latihan, denyut jantung) dibandingkan sekadar catatan subjektif pasien.  
* **Bukti Penguat**: Plavoukou et al. (2025) menyoroti bahwa kendala terbesar digitalisasi terapi adalah ketiadaan protokol standar klinis dan perlunya pengawasan terapis (*biofeedback*) agar gerakan tidak kontraproduktif.

## **4\. Matriks Kebutuhan & Fokus UX/UI Tiap Segmen**

### **4.1 Fokus UX Segmen 1: Pengguna Kursi Roda Aktif**

1. **Kalibrasi *Safety Clearance Boundary* Kursi Roda**:  
   * Sistem harus memiliki tahap inisiasi di mana pengguna merentangkan tangan ke samping dan bawah untuk menandai posisi roda kursi (*rims*) dan sandaran lengan (*armrests*). Target virtual tidak boleh muncul di area benturan fisik ini.  
2. **Gamifikasi Kardio Berbasis Ritme & Daya Dorong**:  
   * Implementasi modul *Seated Boxing* dan *Forward Press* dengan umpan balik haptik variatif (misal: getaran frekuensi rendah untuk pukulan tepat, getaran lembut untuk sentuhan ringan).  
   * Skoring murni berbasis akurasi lengan dan ritme, tanpa penalti mekanik tubuh bagian bawah.  
3. **Pencegahan Disorientasi Visual (*Zero Unintended Locomotion*)**:  
   * Kamera pengguna harus berstatus *fixed ground anchor*. Jika ada pergerakan lingkungan di latar belakang, gunakan garis referensi statis (seperti kokpit virtual atau lantai acuan) guna menekan skor SSQ (disorientasi/nausea).

### **4.2 Fokus UX Segmen 2: Pasien Pemulihan Medis & Lansia**

1. **Kalibrasi Jangkauan Nyaman (*Comfort Range of Motion Calibration*)**:  
   * Sebelum latihan dimulai, sistem meminta pengguna menjangkau target sejauh yang nyaman tanpa rasa nyeri. Algoritma akan menempatkan objek virtual di dalam batas \$\\le 85\\%\$ dari jangkauan maksimal tersebut.  
   * Pilihan konfigurasi independen: Pengguna dapat memilih mode satu tangan jika satu sisi tubuh mengalami hemiparesis, cedera, atau keterbatasan gerak.  
2. **Antarmuka Minimalis & Penurunan Beban Visual**:  
   * Berdasarkan Saredakis et al. (2020), visual yang terlalu ramai memicu *cybersickness*. Gunakan pencahayaan lembut, kontras tinggi yang ramah mata lansia, serta instruktur virtual dengan gerakan lambat dan artikulatif.  
3. **Pemberitahuan Waktu & Beban Leher (*Ergonomic Rest Breaks*)**:  
   * Bobot Meta Quest 2/3 (sekitar 500 gram) membebani otot servikal saat duduk. Berikan pengingat istirahat otomatis setiap 7–10 menit untuk merilekskan bahu dan leher.

### **4.3 Fokus UX Segmen 3: Fisioterapis & Trainer Adaptif**

1. **Panel Kontrol Preskripsi Latihan (*Clinician Dashboard*)**:  
   * Terapis dapat memilih paket gerakan yang disetujui (misal: hanya *Shoulder Rolls* dan *Alternating Reach*, menonaktifkan *Boxing* yang bersifat eksplosif).  
2. **Tele-Monitoring & Ekspor Data Kuantitatif**:  
   * Visualisasi sudut elevasi bahu, kecepatan gerak lengan, serta estimasi persentase denyut nadi puncak (\$\\%HR\_{\\text{peak}}\$).  
3. **Batas Toleransi Fisiologis (*Safety Cut-off*)**:  
   * Fitur integrasi data detak jantung (via sensor Bluetooth). Jika denyut nadi melampaui batas atas zona moderat (\$\>86\\%\$), visual game berubah tenang (*cool-down environment*) dan memandu latihan pernapasan.

## **5\. Panduan Spesifikasi Desain Interaksi (Prototype 8 Minggu)**

Mengacu pada seleksi 5 gerakan prioritas tim Anda (*Forward Arm Reach, Alternating Arm Reach, Side Arm Raise, Forward Press, Seated Boxing*), berikut adalah pedoman interaksi teknis untuk Meta Quest 2/3:

                        ZONA JANGKAUAN VIRTUAL

                                  

                                  \[0°\]

                                   ▲

                                   │  Target: Forward Arm Reach / Press

                        \-45° ◄─────┼─────► \+45°

             Target:               │               Target:

      Side Arm Raise (Kiri)       (•)       Side Arm Raise (Kanan)

                               Pengguna

                             (Posisi Duduk)

1. **Forward Arm Reach & Forward Press**:  
   * **Tinggi Target**: Sejajar dengan tulang dada (*sternum*) pengguna, bukan sejajar mata headset, untuk mencegah rotasi bahu berlebih (*impingement*).  
   * **Mekanik Interaksi**: Penekanan target berbentuk tombol elastis virtual dengan audio klik lembut dan haptik pendek ($50ms$).  
2. **Alternating Arm Reach & Seated Boxing**:  
   * **Jarak Antar Target**: Lebar target tidak melebihi rentang bahu ($35cm-50cm$).  
   * **Dinamika Tempo**: Mulai dari tempo santai ($60BPM$) dan hanya meningkat jika akurasi stabil, menjaga detak jantung pada zona kebugaran tanpa gerakan menyentak (*no sudden jerky movements*).  
3. **Side Arm Raise**:  
   * **Batas Sudut Abduksi**: Sudut lateral dibatasi maksimal $6{0}^{\circ }-7{0}^{\circ }$ dari sumbu tubuh guna menjaga stabilitas pusat gravitasi pengguna di atas kursi.  
4. **Prosedur Darurat (*Fail-Safe Feature*)**:  
   * Menurunkan kedua tangan ke pangkuan selama 2 detik secara otomatis membekukan permainan (*Auto-Pause*), membuka mode *Passthrough* untuk melihat lingkungan nyata.

Jurnal terkait:  
**Plavoukou, T., Apostolakopoulou, K., Papagiannis, G., Stasinopoulos, D., & Georgoudis, G. (2025).** Impact of virtual reality, augmented reality, and sensor technology in knee osteoarthritis rehabilitation: A systematic review. *Cureus*, 17(2), e79011. https\://doi.org/10.7759/cureus.79011

**Embla Flatlandsmo (2023). Novel VR exergaming for wheelchair users: Cybersickness and user experience.** https\://hdl.handle.net/11250/3090583

menentukan gerakan aman (Naufy) :

## **A. Latihan Mobilitas dan Fleksibilitas**

1. **Shoulder Rolls (Rotasi Bahu)**  
   Pengguna menggerakkan bahu secara perlahan ke depan dan belakang untuk membantu menjaga mobilitas dan mengurangi kekakuan. Dalam VR, pengguna mengikuti animasi instruktur virtual.  
2. **Forward Arm Reach (Menjangkau ke Depan)**  
   Pengguna mengulurkan tangan ke depan sejauh yang nyaman. Dalam VR, pengguna menyentuh atau mengambil objek virtual yang muncul di depannya.  
3. **Side Arm Raise (Mengangkat Tangan ke Samping)**  
   Pengguna mengangkat tangan ke samping sesuai kemampuan tanpa memaksakan gerakan. Dalam VR, pengguna menyentuh target yang muncul di sisi kiri atau kanan.  
4. **Elbow Flexion and Extension (Menekuk dan Meluruskan Siku)**  
   Pengguna menekuk siku ke arah tubuh kemudian meluruskannya kembali. Dalam VR, gerakan dapat disimulasikan dengan menarik dan mengembalikan objek virtual.

## **B. Latihan Kardio Ringan**

5. **Seated Boxing (Tinju dalam Posisi Duduk)**  
   Pengguna melakukan pukulan ringan ke depan secara bergantian tanpa gerakan menghentak. Dalam VR, pengguna memukul target virtual yang muncul sesuai ritme. Intensitas dapat disesuaikan dengan kemampuan pengguna.  
6. **Alternating Arm Reach (Menjangkau dengan Tangan Bergantian)**  
   Pengguna menggerakkan tangan kiri dan kanan secara bergantian menuju target. Dalam VR, objek muncul bergantian di berbagai posisi yang masih dapat dijangkau pengguna.  
7. **Seated Swimming Motion (Simulasi Berenang)**  
   Pengguna melakukan gerakan lengan ringan menyerupai berenang dengan jangkauan terbatas. Dalam VR, pengguna berada di lingkungan bawah laut dan mengumpulkan objek melalui gerakan tangan.

## **C. Latihan Kekuatan dan Kontrol Otot**

8. **Seated Biceps Curl (Menekuk Lengan)**  
   Pengguna menekuk lengan menuju bahu kemudian menurunkannya kembali secara terkendali. Dalam VR, gerakan dapat diterapkan melalui aktivitas menarik objek virtual. Tanpa resistansi tambahan, latihan ini terutama melatih gerakan dan kontrol lengan, bukan peningkatan kekuatan secara signifikan.  
9. **Forward Press (Mendorong ke Depan)**  
   Pengguna mendorong kedua tangan atau satu tangan ke depan secara perlahan. Dalam VR, pengguna dapat mendorong tombol, pintu, atau objek virtual.  
10. **Seated Row (Gerakan Menarik)**  
    Pengguna menarik tangan ke arah tubuh seperti gerakan mendayung. Dalam VR, gerakan dapat disimulasikan dengan menarik tuas atau mendayung perahu virtual. Untuk latihan kekuatan yang sebenarnya, diperlukan resistansi tambahan yang sesuai.

## **D. Gerakan yang Direkomendasikan untuk Prototype 8 Minggu**

Berdasarkan kemudahan implementasi di Meta Quest 2/3, gerakan yang paling direkomendasikan adalah:

1. **Forward Arm Reach:** Mudah dideteksi melalui posisi tangan atau controller dan dapat diterapkan melalui permainan menyentuh objek.  
2. **Alternating Arm Reach:** Cocok untuk melatih koordinasi tangan dan aktivitas fisik ringan.  
3. **Side Arm Raise:** Melatih jangkauan gerak lengan ke samping dengan target virtual yang dapat disesuaikan.  
4. **Forward Press:** Mudah diimplementasikan melalui mekanisme mendorong objek virtual.  
5. **Seated Boxing:** Memberikan variasi aktivitas kardio ringan melalui permainan memukul target dengan intensitas terkendali.

Kelima gerakan tersebut dapat dikembangkan menjadi satu atau beberapa minigame menggunakan sistem tracking dan kalibrasi yang sama.

## **E. Pertimbangan Keselamatan**

* Seluruh latihan dilakukan dalam posisi duduk yang stabil dan tidak mengharuskan pengguna berdiri.  
* Posisi target VR harus disesuaikan dengan jangkauan gerak nyaman setiap pengguna.  
* Gerakan tidak boleh menyebabkan nyeri, kehilangan keseimbangan, atau memaksa pengguna menjangkau terlalu jauh.  
* Hindari gerakan bahu yang terlalu cepat, berulang secara berlebihan, atau membutuhkan tenaga besar.  
* Sediakan pilihan menggunakan satu tangan atau kedua tangan.  
* Pengguna dapat mengatur intensitas, durasi, dan menghentikan latihan kapan saja.  
* Gerakan dan protokol latihan perlu ditinjau oleh fisioterapis atau tenaga kesehatan terkait sebelum diuji pada pengguna dengan kondisi fisik berisiko.

**Kesimpulan:** Untuk tahap prototype, latihan menjangkau, mendorong, dan tinju ringan merupakan pilihan yang paling realistis karena mudah diintegrasikan dengan tracking Meta Quest 2/3. Fokus utama pengembangan adalah menghasilkan pengalaman olahraga VR yang adaptif, mudah digunakan, dan memperhatikan keselamatan pengguna dengan keterbatasan mobilitas tubuh bagian bawah.

# **Desain Gameplay** : 

[https\://www\.figma.com/design/y3Qk2DL1iYYFwcp0Lmq8da/Untitled?node-id=0-1\&t=t7dM1qQXo11I3vod-1](https://www.figma.com/design/y3Qk2DL1iYYFwcp0Lmq8da/Untitled?node-id=0-1&t=t7dM1qQXo11I3vod-1)

apa yang dibutuhkan di unity/meta quest 3 (mbud) :

# **Kebutuhan Teknis Pengembangan Accessible Seated VR Fitness App**

## **1\. Gambaran Umum Aplikasi**

Accessible Seated VR Fitness App merupakan aplikasi olahraga berbasis Virtual Reality (VR) yang dirancang untuk pengguna dengan keterbatasan mobilitas tubuh bagian bawah, khususnya pengguna kursi roda.

Aplikasi berfokus pada latihan tubuh bagian atas (*upper-body exercise*) yang dapat dilakukan dalam posisi duduk. Aktivitas olahraga dikemas melalui permainan interaktif dengan tingkat kesulitan yang dapat disesuaikan berdasarkan kemampuan fisik pengguna.

## **2\. Platform dan Teknologi Pengembangan**

| Komponen | Teknologi | Fungsi |
| :---- | :---- | :---- |
| Game Engine | Unity | Pengembangan lingkungan dan gameplay VR. |
| VR Headset | Meta Quest 2 / Quest 3 | Perangkat utama untuk menjalankan aplikasi. |
| Bahasa Pemrograman | C\# | Implementasi logika gameplay dan interaksi. |
| XR Framework | OpenXR \+ XR Interaction Toolkit | Integrasi perangkat VR dan tracking. |
| Interaction | Controller Tracking | Mendeteksi pergerakan tangan pengguna. |
| UI/UX Design | Figma | Perancangan antarmuka dan alur aplikasi. |
| 3D Modeling | Blender / Unity Assets | Pembuatan objek dan lingkungan virtual. |
| Version Control | GitHub | Pengelolaan kode dan kolaborasi tim. |

Aplikasi dikembangkan sebagai *standalone VR application* sehingga dapat dijalankan langsung melalui headset tanpa memerlukan komputer selama penggunaan.

## **3\. Jenis Gerakan Olahraga**

Terdapat lima gerakan utama yang direncanakan untuk diimplementasikan dalam aplikasi.

| Gerakan | Implementasi VR | Kompleksitas |
| :---- | :---- | :---- |
| Forward Arm Reach | Menjangkau dan menyentuh target virtual di depan tubuh. | Rendah |
| Alternating Arm Reach | Menyentuh target yang muncul bergantian di kiri dan kanan. | Rendah |
| Side Arm Raise | Mengangkat tangan ke samping untuk mencapai target virtual. | Sedang |
| Forward Press | Mendorong objek virtual menggunakan satu atau kedua tangan. | Rendah |
| Seated Boxing | Melakukan pukulan ringan ke target virtual mengikuti ritme tertentu. | Sedang |

Seluruh gerakan dilakukan dalam posisi duduk dan disesuaikan dengan jangkauan nyaman masing-masing pengguna. Gerakan yang membutuhkan keseimbangan tubuh berlebihan atau perpindahan posisi kaki tidak diterapkan.

## **4\. Fitur Utama Aplikasi**

| Fitur | Deskripsi |
| :---- | :---- |
| Seated Mode | Seluruh aktivitas dapat dilakukan dalam posisi duduk. |
| Body Calibration | Menyesuaikan tinggi dan jangkauan tangan pengguna sebelum latihan. |
| Adaptive Difficulty | Mengatur jarak target, ukuran objek, dan kecepatan permainan. |
| One-Hand / Two-Hand Mode | Mendukung latihan menggunakan satu atau kedua tangan. |
| Interactive Gameplay | Menampilkan objek virtual yang dapat disentuh, didorong, atau dipukul. |
| Scoring System | Menghitung jumlah gerakan, skor, dan akurasi latihan. |
| Progress Tracking | Menampilkan durasi dan hasil latihan pengguna. |
| Safety System | Menyediakan pause, stop, pengingat istirahat, dan pembatasan jangkauan target. |
| Haptic Feedback | Memberikan respons getaran controller ketika berinteraksi dengan objek. |

## **5\. Alur Penggunaan Aplikasi**

Alur penggunaan aplikasi dirancang sebagai berikut:

1. **Main Menu:** Pengguna memulai aplikasi.  
2. **Calibration:** Sistem menyesuaikan posisi duduk dan jangkauan tangan.  
3. **Exercise Selection:** Pengguna memilih jenis latihan dan tingkat kesulitan.  
4. **VR Gameplay:** Pengguna melakukan gerakan olahraga melalui interaksi dengan objek virtual.  
5. **Exercise Results:** Sistem menampilkan skor, akurasi, dan durasi latihan.

Sistem gameplay memanfaatkan *controller tracking*, *collision detection*, dan *target spawning* untuk mendeteksi serta mengevaluasi interaksi pengguna.

## **6\. Rencana Pengembangan**

| Minggu | Aktivitas | Target |
| :---- | :---- | :---- |
| 1 | Setup Unity, OpenXR, dan Meta Quest | Lingkungan VR berjalan. |
| 2 | Implementasi controller tracking | Interaksi dengan objek virtual. |
| 3 | Implementasi sistem kalibrasi | Penyesuaian posisi dan jangkauan tangan. |
| 4 | Pengembangan tiga gerakan awal | Tiga latihan dapat dimainkan. |
| 5 | Pengembangan dua gerakan tambahan | Lima latihan dapat dimainkan. |
| 6 | Integrasi UI, scoring, dan safety system | Sistem terintegrasi. |
| 7 | Pengujian fungsional dan usability | Evaluasi dan perbaikan aplikasi. |
| 8 | Finalisasi dan dokumentasi | Prototipe siap didemonstrasikan. |

## **7\. Batasan Pengembangan**

Pengembangan difokuskan pada implementasi lima gerakan olahraga, sistem interaksi berbasis controller, kalibrasi kemampuan gerak, penyesuaian tingkat kesulitan, dan fitur keselamatan dasar.

Fitur tambahan seperti *hand tracking*, integrasi sensor detak jantung, analisis biomekanika, dan penyimpanan data berbasis cloud tidak menjadi prioritas dalam pengembangan awal.

Aplikasi dikembangkan sebagai prototipe olahraga interaktif, bukan perangkat rehabilitasi medis. Pengujian keselamatan gerakan pada pengguna dengan keterbatasan fisik memerlukan penilaian lebih lanjut dari tenaga profesional.

## **8\. Hasil yang Diharapkan**

Hasil akhir pengembangan berupa prototipe aplikasi VR yang memungkinkan pengguna dengan keterbatasan mobilitas tubuh bagian bawah melakukan lima jenis latihan tubuh bagian atas secara interaktif dalam posisi duduk.

Prototipe diharapkan dapat mendemonstrasikan penerapan teknologi VR untuk mendukung aksesibilitas aktivitas olahraga melalui sistem interaksi adaptif, kalibrasi kemampuan pengguna, dan mekanisme permainan yang memperhatikan kenyamanan serta keselamatan.

