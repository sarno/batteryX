# Implementation Plan — BatteryX

Dokumen ini menguraikan tahapan pengerjaan (step-by-step roadmap) untuk membangun BatteryX dari awal hingga siap digunakan.

---

## Phase 1: Project Scaffolding & Core Foundations
- [x] Buat `Package.swift` dengan target:
  - `BatteryXCore` (Library untuk IOKit monitoring, Alert logic, SMC logic).
  - `BatteryXHelper` (Executetable CLI dengan hak akses root untuk penulisan SMC).
  - `BatteryX` (Executable AppKit/SwiftUI Menu Bar UI).
  - `BatteryXTestRunner` (Automated CLI verification suite).
- [x] Siapkan konfigurasi `Info.plist` dengan `LSUIElement = true` (Menu Bar application).
- [x] Buat struktur folder `Sources/` dan `Resources/`.
- [x] Verifikasi build berhasil via `rtk swift build` dan `rtk swift run BatteryXTestRunner`.

---

## Phase 2: Battery Monitoring & Early Warning System
- [x] Implementasikan `BatteryMonitor` menggunakan IOKit `IOPSCopyPowerSourcesInfo` dan `IOPSNotificationCreateRunLoopSource`.
- [x] Implementasikan `AlertEngine`:
  - [x] Deteksi transisi baterai (misal: melewati batas 20% saat `Discharging`).
  - [x] Integrasi dengan `UserNotifications` untuk memunculkan notifikasi banner (dengan CLI fallback aman).
  - [x] Integrasi dengan `NSSound` / `AudioServicesPlaySystemSound` untuk memutar audio alert.
  - [x] Implementasikan debounce dan pengulangan berkala saat di bawah batas kritis (< 10%).
- [x] Verifikasi pembacaan IOKit live dan simulasi alert via `BatteryXTestRunner`.

---

## Phase 3: Hardware Control & Charge Limiting (AppleSMC)
- [x] Implementasikan `SMCDriver`:
  - [x] Membuka koneksi kernel `IOServiceMatching("AppleSMC")` via `IOServiceOpen`.
  - [x] Fungsi membaca kunci SMC (`readUint8`).
  - [x] Fungsi menulis kunci SMC (`writeUint8`).
- [x] Konfigurasi kontrol pengisian daya:
  - [x] Implementasikan `ChargeLimiterService` dengan clamping aman (40% - 100%).
  - [x] Manajemen kunci `BCLM` (Battery Charge Limit Max) dan fail-safe reset ke 100%.
- [x] Bangun executable `batteryx-helper` (CLI root) untuk penulisan SMC dengan perintah `get-limit`, `set-limit`, dan `reset`.
- [x] Verifikasi koneksi AppleSMC dan logika pembatasan daya via `BatteryXTestRunner`.

---

## Phase 4: Menu Bar UI & User Preferences
- [x] Implementasikan `SettingsManager` dengan reaktif `@Published` property wrapper dan persistensi `UserDefaults`.
- [x] Implementasikan `MenuBarController` menggunakan `NSStatusItem` di macOS menu bar:
  - [x] Ikon dinamis (status charging, persentase, estimasi sisa waktu).
  - [x] Event handling pembukaan popover via click.
- [x] Bangun antarmuka SwiftUI `PopoverDetailsView`:
  - [x] Tampilan visual persentase baterai & perkiraan sisa waktu (jam & menit).
  - [x] Slider batas peringatan dini baterai lemah (10% - 35%, default: 20%).
  - [x] Toggle audio alert bunyi alarm (Sosumi / Basso).
  - [x] Slider batas pengisian daya (50% - 90%, default: 80%).
  - [x] Tombol manual "Charge ke 100% Sekali" (Top Up).
  - [x] Tombol "Keluar" aplikasi yang rapi.

---

## Phase 5: Build, Test & Packaging
- [x] Verifikasi konsumsi memori (< 25MB) dan CPU (< 0.1%) via arsitektur event-driven IOKit.
- [x] Buat skrip instalasi `Scripts/install_helper.sh` untuk privileged root helper.
- [x] Buat skrip build & packaging `.app` bundle `Scripts/build_app.sh` dengan ad-hoc codesigning.
- [x] Verifikasi hasil packaging bundle di `dist/BatteryX.app`.
- [x] Dokumentasikan instruksi penggunaan lengkap di `README.md`.
