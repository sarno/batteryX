# Product Requirements Document (PRD) — BatteryX

## 1. Problem Statement
Pengguna MacBook yang menggunakan komputasi berat sering mengalami situasi di mana baterai lupa di-charge saat beroperasi dengan baterai hingga mencapai level kritis 1%. 
Ketika charger (bahkan adaptor berdaya tinggi seperti 96W) dicolok saat baterai sudah di level 1%, sel baterai sulit menaikkan persentase karena:
1. *Battery Management System* (BMS) membatasi arus pengisian pada titik tegangan sel paling bawah demi proteksi termal.
2. Beban kerja aplikasi menyerap sebagian besar alokasi daya dari adaptor.
3. Mengharuskan pengguna mematikan laptop dan menunggu sampai 30% baru bisa digunakan kembali.

Selain itu, ketika laptop dicolok charger terus-menerus, membiarkan baterai selalu berada di level 100% mempercepat degradasi kesehatan baterai.

## 2. Product Vision & Goals
**BatteryX** adalah utilitas gratis, open-source, dan native macOS yang menggabungkan:
1. **Early Warning System (Anti-1% Drop)**: Peringatan dini interaktif (audio + visual banner) ketika baterai menyentuh persentase kustom (default: 20%) agar pengguna sempat mencolok charger sebelum terlambat.
2. **Charge Limiting (Battery Longevity)**: Membatasi pengisian baterai hingga persentase tertentu (misalnya 80%) secara otomatis tanpa biaya langganan seperti aplikasi berbayar.
3. **Lightweight & Clean Menu Bar Interface**: Menggantikan atau melengkapi indikator baterai bawaan macOS dengan UI yang elegan, cepat, dan hemat memori (< 25MB RAM).

---

## 3. User Personas & Use Cases

### User Persona
* **Power Users & Developers**: Sering membuka IDE, Docker, browser banyak tab, rendering, atau machine learning task dengan beban CPU/GPU tinggi.
* **Desk + Mobile Hybrid**: Sering berpindah antara mode colok charger dan mode mobile tanpa charger.

### Primary Use Cases
1. **Peringatan Dini Saat Discharging**:
   * *Aksi*: Pengguna sedang bekerja tanpa charger. Baterai menyentuh 20%.
   * *Hasil*: Suara peringatan khas berbunyi dan notifikasi banner muncul: *"Baterai 20%! Segera colok charger 96W Anda untuk mencegah penurunan daya kritis."*
2. **Pengisian Daya Dibatasi di 80%**:
   * *Aksi*: Pengguna mencolok charger 96W dan bekerja seharian di meja kerja.
   * *Hasil*: Begitu baterai menyentuh 80%, BatteryX memerintahkan kontrol daya untuk menghentikan pengisian dan mengalihkan pasokan daya langsung ke sistem (baterai bypass).
3. **Pengisian Penuh Sesaat (Top Up)**:
   * *Aksi*: Pengguna akan bepergian keluar kantor dan butuh baterai penuh 100%.
   * *Hasil*: Pengguna menekan tombol "Charge to 100% Once", dan BatteryX mengabaikan batas 80% untuk satu sesi pengisian tersebut.

---

## 4. Key Functional Requirements

| ID | Fitur | Deskripsi | Prioritas |
| :--- | :--- | :--- | :--- |
| **FR-01** | Low Battery Warning | Pengguna dapat menentukan batas peringatan (10% - 35%, default: 20%). | P0 (Must Have) |
| **FR-02** | Aggressive Sound Alert | Memutar bunyi peringatan saat ambang batas tercapai saat laptop discharging. | P0 (Must Have) |
| **FR-03** | Repeat Alert on Critical | Jika baterai turun ke 10% dan belum dicolok, notifikasi diulang setiap 60 detik. | P1 (High) |
| **FR-04** | Charge Limiter | Menghentikan pengisian pada batas kustom (40% - 90%, default: 80%). | P0 (Must Have) |
| **FR-05** | Privileged Helper Tool | CLI/Daemon kecil yang mengeksekusi penulisan SMC dengan aman. | P0 (Must Have) |
| **FR-06** | Fail-Safe Reset | Reset ke pengisian normal (100%) jika helper dimatikan atau Mac restart. | P0 (Must Have) |
| **FR-07** | Menu Bar Interface | Ikon menu bar informatif dengan sisa waktu, persentase, dan popover pengatur. | P1 (High) |
| **FR-08** | One-Click Bypass / Top-up | Opsi sekali klik untuk mengisi baterai ke 100% saat hendak bepergian. | P2 (Nice to Have) |

---

## 5. Non-Functional Requirements
* **Platform**: macOS 13 (Ventura), macOS 14 (Sonoma), macOS 15+, arsitektur x86_64 (Intel) dan arm64 (Apple Silicon).
* **Performa**: Penggunaan memori < 25 MB RAM, konsumsi CPU rata-rata < 0.1%.
* **Zero Polling Abuse**: Menggunakan IOKit Power Notification RunLoop source.
* **Lisensi**: Bebas dan Open Source (MIT License).
