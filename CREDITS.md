# Credits & Attribution

**ZenoFit** is a seated upper-body VR active-break game developed for the **Extended Reality (EF234711 / EA234505)** course at **Institut Teknologi Sepuluh Nopember (ITS)**.

---

## Third-Party Assets (External Attribution)

| Asset | Creator | Source | License | Modifications |
| :--- | :--- | :--- | :--- | :--- |
| **Japanese Traditional Room** (`asset/Environment.glb` → `godot/assets/Environment.glb`) | [`jrevel`](https://sketchfab.com/jrevel) | [Sketchfab (`https://skfb.ly/ounpS`)](https://skfb.ly/ounpS) (Model ID: `69175f3d695d4950b0cae35ecd3294df`) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (Creative Commons Attribution 4.0 International) | Runtime scene cleanup via `DojoEnvironmentLoader`: stripped 28 stray external modular nodes outside the main room, centered the room to the seated `BodyFrame`, disabled real-time shadow casting, and enabled `CULL_DISABLED` on shoji surfaces. |

---

## Generated 3D Assets (Final Build)

- **Zeno Mascot** (`asset/Zeno_WithTexture.glb` → `godot/assets/Zeno_WithTexture.glb`) — Original team mascot design generated with **Claude Sonnet 5.5** and prepared in **Blender** (`66,480` tris, embedded PBR textures).
- **Karate Breaking Board** (`asset/Objects/KarateBoard.glb` → `godot/assets/KarateBoard.glb`) — Generated with **Claude Sonnet 5.5** (`604` tris, intact/split/splinter meshes and `Break` animation) for *Board Smash*, *Wide Split*, and *Torso Twist*.
  - **Reference Image Source:** [3mm Thickness Martial Arts Taekwondo Karate Paulownia Pine Wood Breaking Board (Made-in-China)](https://image.made-in-china.com/202f0j00BYCkIMemSqry/3mm-Thickness-Martial-Arts-Taekwondo-Karate-Paulownia-Pine-Wood-Breaking-Board.webp)

---

## Engine, Standards & Tools

- **Godot Engine** (`4.7.2.stable`, MIT License — `GDScript`, `gl_compatibility` renderer)
- **OpenXR** (Khronos Group — Local / Seated Reference Space for PICO 4 Ultra & Meta Quest 2/3/3S)
- **Blender** (3D asset preparation and inspection)

---

## Development Team

**Team ZenoFit — Group 4 (Lebah Ganteng)** · **Institut Teknologi Sepuluh Nopember (ITS)**

| Name | GitHub | Role |
| :--- | :--- | :--- |
| Muhammad Naufal Dzakwan | [@Mafuruko](https://github.com/Mafuruko) | Project Manager & UI Designer|
| Muhammad Rafi Budiman | [@Gembut](https://github.com/Gembut) | Asset Manager |
| Rynofaldi Damario Dzaki | [@RYDDZ2](https://github.com/RYDDZ2) | Game Developer |
| Ryan Marvin Sirait | [@vinmarvin](https://github.com/vinmarvin) | Game Developer |

---

## Disclaimer

> ZenoFit is a preventive seated active-break game and is **not** a medical or therapeutic device.
