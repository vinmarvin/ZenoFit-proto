# ZENOFIT · Group Assignment 3 · Real and Generated

**Extended Reality · Realitas X · EF234711 / EA234505 · Semester 2026/1**
**Team:** Lebah ganteng / Izanagi (Team 3) · **Class:** IF
**Due:** IF Thu 19 Nov 2026, 09:40 WIB · RKA Fri 20 Nov 2026, 12:30 WIB. The last commit to `main` before that moment is what is marked.

<!-- > **How to use this template.** Save this file as `GA3.md` in the root of your final-project repository. Replace every `___` and every `[bracket]`. Delete these grey quote blocks when you are done.
> Small screenshots (PNG or JPG, under 5 MB each) go in a folder `ga3/` in the repo. **Everything large goes in your team's cloud folder**: the scan files, the generated model, the fitted versions, the video, and a build if it is not hosted online. Paste the links in the table below.
> Your Week 10 Scan Log (FigJam team area) already holds most of Section 1. Copy it here and update it; do not start again.
> **The quality of your English is not marked.** Where, what, why and how many are what count.
> **GenAI level for this assignment: C** (working aid, disclosed). You may use AI tools for writing help and to generate your second asset. Free tools or free plans only. Section 7 is required. -->

## Links

| What | Link |
|---|---|
| Team cloud folder (OneDrive ITS or Google Drive, "anyone with the link can view") | [Google Drive](https://drive.google.com/file/d/1NFKmkRtai_krZozbCAx809dXspSZyB4l/view?usp=share_link) |
| Video demo (in the folder; 2 to 3 minutes) | [Video Reading](https://drive.google.com/file/d/1qTLK9LAFIkbMh8eGy3o3lqaXRBiQ3KPO/view?usp=drive_link) <br> [Demo App](https://drive.google.com/file/d/1NiDAiHX2FdM8fLjXk2XzHL0E3n3p-VE_/view?usp=drive_link)|
| Build: hosted page (WebXR) or build file in the folder (Unity, other) | [Godot APK](https://drive.google.com/file/d/19PzAZT0Y1dNtoJMhepti6lpTzVGm5wGo/view?usp=drive_link) |

**Files in the cloud folder** (the TA checks that names, sizes and dates match this list; nothing in the folder may change after the deadline)

| File | What it is | Size (MB) | Last modified (date, time WIB) |
|---|---|---|---|
| `scan_raw.glb` | Reconstruction as it came out of the tool | 4 MB | 18 Nov 2026, 16.17 |
| `scan_fitted.glb` | Reconstruction after cleaning and fitting | 3,6 MB | 18 Nov 2026, 16.18 |
| `gen_raw.glb` | Original AI-generated Zeno mascot | 648 KB | 18 Nov 2026, 15.48|
| `gen_fitted.glb` | Generated asset after fixing and fitting | 4.78 MB | 18 Nov 2026, 15.48 |
| `GA3_video.mp4` | Video demo | | |
| [build file, if any] | | | |

## 0 · Our assignment in four lines

<!-- > Read this aloud at the start of your video. -->

**What we scanned.** We reconstructed a water bottle from 58 photos taken on 9 Nov 2026, as a 3D mesh, because in our app the user can pick it up, hold it, and interact with it inside the virtual fitness studio.

**What we generated.** We generated Zeno, our 3D mascot character, with Claude Sonnet 5.5 from our own mascot reference image. The character includes animations and is intended to demonstrate stretching movements. We could not capture it because Zeno is a fictional character that does not exist in the real world.

**Where they live.** Both are in our Godot Scene for Meta Quest headset, at 66.480 and 5.204 of our budget.

**What still does not work.** The mascot's existing animations do not yet include all the stretching movements required for exercise demonstrations.


---

## 1 · Reconstruction (the real asset)

### 1.1 Route Card

| Item | Our answer |
|---|---|
| Stack (WebXR, Unity, other) | Godot |
| Target headset (sets the budget; GA3 needs no headset build) | Meta Quest |
| Object or space (matte, glossy, thin, large space) | A water bottle with a matte surface |
| Asset we build in (splat or mesh) and why | Mesh, because it is easier to clean, edit, scale, and integrate into Godot as an interactive object |
| Tool and version (copied from the app's About screen) | Polycam 7.0.9 |
| Photos used (of how many), or video length | 58 Photos |
| Capture Plan version used for the final capture | V2 — We replaced the transparent plastic bottle with a matte water bottle after the initial reconstruction produced poor results with multiple holes |
| Real length we measured (what, how many cm) | Bottle height: 21 cm, Diameter 6,5 cm|

### 1.2 Defect table (four looks, on the final reconstruction)

<!-- > Orbit along your path, then off path (30 cm to the side), then behind, under or above, then close. Every defect gets a place and a slot: SUBJECT, PATH, CONDITIONS or CHECK. -->

| Look | What we see | Where | Cause | Slot |
|---|---|---|---|---|
| Orbit | The bottle  is recognizable, but its body appears slightly dented | Bottle body | Possible inaccuracies in surface reconstruction. | SUBJECT |
| Off path | The bottle's silhouette appears uneven and slightly distorted from an angled view | Side of the bottle | Possible insufficient coverage from different capture angles | PATH |
| Behind, under, above | The bottom of the bottle was not reconstructed and required manual filling | Bottom of the bottle | The bottom was obstructed by the table during photo capture | PATH |
| Close | Some textures appear slightly blurry, and the edges of the bottle cap are rough | Bottle cap, body surface, and small printed details | Possible limitations in capturing and reconstructing fine details | SUBJECT |

### 1.3 What we repaired

| Slot | Plan line before | Plan line after | Did we recapture? What changed in the result? |
|---|---|---|---|
| CHECK | The reconstructed bottle included unwanted table object | Inspect and remove unnecessary surrounding object | No. We cleaned the existing reconstruction in Blender by removing the table |
| SUBJECT | V1: Use a transparent plastic bottle |  V2: Replace it with a matte water bottle | Yes. The new reconstruction was more complete and had no holes |
| PATH | The bottom of the bottle was obstructed by the table during capture | Manually fill the missing bottom surface | No. We reconstructed the missing bottom surface using Blender |

### 1.4 Cleaning and scale

- **Removed by hand:** We used Blender to remove the unwanted table geometry and manually fill the missing bottom surface of the bottle.
- **Scale:** the real bottle height is 21 cm; in our build it measures 21,21 cm (screenshot `ga3/scale.png`).

![Reconstruction in our build](ga3/scan_in_build.png)
*Figure 1. Water Bottle in our build, seen from Table. Date of screenshot: 18 Nov 2026.*

---

## 2 · Generated asset

### 2.1 Asset Card

| Item | Our answer |
|---|---|
| What the asset is | Our Mascot Character |
| Why our app needs it | To demonstrate the movement |
| Why we could not capture it (does not exist, too far, too big, cannot be photographed safely, not ours to photograph) | it does not exist |
| Tool, model version, and plan (free) | Claude Sonnet 5.5 |
| Input: the exact prompt, or the input image (our own photo or drawing, saved as `ga3/gen_input.png`) | ![zeno](ga3/gen_input.png) <br> Can you create a 3D asset from this image? and i can export it. Make the asset so i can open it on Blendr or Unity |
| Date and account used | 12 November 2026 |
| How many attempts before we kept one | 4 |

<!-- > **Rules for this asset.** No real person's face or voice without that person's written consent. No characters, logos or designs that belong to someone else. If the input is an image, it must be your own photo or drawing, or one whose licence you can show. -->

### 2.2 Four looks on the generated asset

<!-- > A generated asset was seen from nowhere: every side is a guess. Look at it the same way you looked at your scan. -->

| Look | What we see | Where | Why we think the tool did this |
|---|---|---|---|
| Front (the side the input showed) | The mascot closely resembles the original image, including its rounded head, dark face, eyes, smile, body, and arms. | Front of the character | The tool followed the visible shapes and colors from the reference image. |
| Back and sides (never shown) | The rounded shapes are expected to continue around the body, but the actual details need further inspection. | Behind the head, torso, and arms | The tool estimated the missing geometry because the input only showed the front. |
| Under and inside | The character has no visible legs, following the original floating mascot design. The underside and internal geometry have not been inspected. | Bottom of the torso and inside the model | The tool prioritized the character's visible external appearance. |
| Close (texture, edges, small parts) | Smooth surfaces and rounded edges. The chest logo, eyes, and smile are slightly different from the original image. | Face, chest logo, and arm connections | The tool simplified small details when converting the 2D reference into a 3D model. |

### 2.3 What we fixed by hand

- We corrected the placement of misplaced objects in the generated asset using Blender. We adjusted their positions to ensure proper alignment and maintain the intended appearance of the mascot.

<img width="700" height="800" alt="image" src="https://github.com/user-attachments/assets/cbad5dc1-966f-4c47-b4f8-88a0bd59a3c5" /> <br>
*Figure 2. Our Mascot in our build. Date of screenshot: 18 Nov 2026.*

---

## 3 · Build integration and budget

### 3.1 Our Budget Line

| Item | Our answer |
|---|---|
| Target headset | Meta Quest |
| Budget for the whole scene (triangles or splats; source and date) | 1,300,000 triangles per frame for the entire scene. This is the lower end of Meta’s 1.3M–1.8M range for Quest 3/3S. Source: Meta Horizon, Unity performance, page updated 30 Oct 2024, accessed 18 Nov 2026. |
| Our share for the reconstruction | 1 % = 13,000. The bottle is currently 5,204, so it fits. |
| Our share for the generated asset | 1.5 % = 19,500. Zeno is currently 66,480, so it does not fit yet. The ratio is 19,500 ÷ 66,480 = 0.29, which I’d round to 0.3, giving about 19,900 triangles. |

### 3.2 Before and after

| Asset | Count before (triangles or splats) | Count after | File size before / after (MB) | Texture size before / after | How we reduced it (tool, setting) | Times over our share, before / after |
|---|---|---|---|---|---|---|
| Reconstruction | 5,204 | 5,204 | 3,6 / 3,6 | 4096 x 4096 | Removed table geometry and filled the missing bottom surface using Blender | 0% |
| Generated asset | 66,480 | 19,900 | 4.78 / N/A | N/A | Corrected misplaced objects using Blender. The fitted asset includes animations | 70% |

**Where the counts come from:** Blender's Statistics overlay

**What we gave up to fit:** The reconstructed bottle retains minor surface deformation, and its bottom surface was manually reconstructed. The generated mascot retains its intended appearance, but some small details differ from the original reference image.

### 3.3 Running in the build

- **Where it runs:** Godot Scene (browser and version, or desktop build). A headset is not required for GA3; the same build is tested on headsets in Group Assignment 4.
- **Frame rate we saw, if we measured it (optional):** -

<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/99b09e05-a71a-461a-9da8-b3cecf73f46a" />
*Figure 3. Both assets in one view of our build. Date of screenshot: 18 Nov 2026.*

---

## 4 · Provenance

Our provenance log is **README Section 11**. For GA3 it must have at least these rows, complete: the reconstruction, the generated asset, and every other asset in the same scene that we did not make by hand.

- [x] Row for the reconstruction: tool and version, capture date and place, by whom (whose account), upload terms or licence, hand edits, what in the scan is not ours.
- [x] Row for the generated asset: tool and model version, prompt or input image, date, by whom (whose account), licence of the output (for example, CC BY 4.0 on a free plan means we must credit the tool), hand edits.
- [x] Rows for any other asset in the scene.

---

## 5 · Video demo

<!-- > 2 to 3 minutes, **one continuous recording** of the build on a screen (no cuts). Every member speaks about the part they did. Show at least one view **off your photo path**, where the scan breaks. A Zoom call with screen sharing, recorded, is the easiest way; members can join from home. -->

| Time in the video | Member | What they show and say |
| :--- | :--- | :--- |
| 0:00 | Muhammad Naufal Dzakwan | Perkenalan Tim 3 (Izanagi / Lebah Ganteng) yang beranggotakan Muhammad Naufal Dzakwan, Ryan Marvin, Rafi Budiman, dan Rynofaldi Damario, serta pengantar tugas GA3. |
| 0:30 | Rafi Budiman | Penjelasan pembuatan aset: rekonstruksi botol air dari 58 foto menggunakan aplikasi Polycam untuk *virtual fitness studio*, serta pembuatan maskot fiktif "Zeno" menggunakan Claude Sonnet 3.5 (5.5). |
| 1:30 | Rafi Budiman | Pembahasan kendala botol transparan (banyak lubang), penggantian dengan botol *matte*, perbaikan bagian bawah botol menggunakan Blender, serta pengecekan ukuran nyata (21 cm vs hasil scan 21.2 cm). |
| 2:45 | Rafi Budiman | Pembahasan detail maskot Zeno yang digenerate AI (tampak depan dan belakang, permukaan halus, serta perbaikan penempatan logo di tengah). |
| 4:15 | Rynofaldi Damario | Pembahasan anggaran integrasi target headset Meta Quest (total bujet 1,3 juta), persentase alokasi rekonstruksi (1%), dan aset yang digenerate AI (1,5%). |
| 5:30 | Rynofaldi Damario | Penjelasan optimasi *triangle count* aset: botol (0% perubahan), sedangkan maskot Zeno dioptimasi dari 66.000 menjadi 19.000 *triangle*, serta sukses diimpor ke *scene* Godot. |
| 7:15 | Ryan Marvin | Pembahasan batasan/kendala pada aset rekonstruksi (bagian bawah botol tertutup meja) dan aset AI (sisi belakang kurang referensi visual sehingga perlu penyesuaian). |
| 8:30 | Ryan Marvin | Penjelasan pemanfaatan AI sebagai *working aid* menggunakan ChatGPT, Claude, dan Gemini, serta proses inspeksi geometri, material, dan resolusi tekstur pada kedua aset. |

---

## 6 · Limitation (required)

**Our scan** is trustworthy from the front to the sides, but not from underneath, because the bottom of the bottle was obstructed by the table during photo capture and had to be manually reconstructed.
**Our generated asset** looks right from the front, but its back and underside may differ from the original design, because the tool never never received reference images from those angles.
**If we had one more week, we would** improve the bottle reconstruction to reduce surface deformation and add stretching animations to Zeno.

---

## 7 · AI Use Statement (Level C)

| Item | Our answer |
|---|---|
| Level | C (working aid, disclosed) |
| Tools (name and version) | Chat GPT, Claude, Gemini |
| What we used them for | Generating the 3D mascot, assisting with technical development, and improving the assignment documentation |
| What we checked ourselves, and how | We inspected both assets in Blender, checked their geometry and materials, measured the bottle's dimensions, inspected the triangle counts and texture resolutions, and manually corrected misplaced objects |
| One thing we disagreed with an AI tool about, and what we did instead | The AI didnt count the budget properly, so we do it manually |

<!-- > Never put personal data of other people, class recordings or passwords into an AI tool. -->

---

## Sign-off

<!-- > Each member adds their own line, ticked, **in a commit made from their own GitHub account**, so the history shows who agreed. -->

- [x] Muhammad Naufal Dzakwan, 5025231234 · My part was Making the generative asset · I have read this GA3.md and agree it is true · date 18 November 2026
- [x] Muhammad Rafi Budiman, 5025231297 · My part was Scanning the real life object · I have read this GA3.md and agree it is true · date 18 November 2026
- [x] Rynofaldi Damario Dzaki, 5025231042 · My part was making the Godot Scene · I have read this GA3.md and agree it is true · date 18 November 2026
- [x] Ryan Marvin Sirait, 5025231215 · My part was the Godot Scene · I have read this GA3.md and agree it is true · date 18 November 2026
