# Sipades Mobile 
 **Sistem Pengelolaan Aset Desa berbasis Mobile**

Project ini merupakan aplikasi mobile yang dirancang untuk kebutuhan digitalisasi, inventarisasi, pencatatan, serta pengelolaan aset-aset milik desa agar lebih transparan, akuntabel, dan efisien. Aplikasi dibangun dengan arsitektur multi-platform sehingga siap dideploy ke berbagai perangkat yang digunakan oleh perangkat desa.

---

## Spesifikasi Teknologi & Tools (Tech Stack)

Berdasarkan analisis struktur repositori dan dependensi platform yang digunakan, berikut adalah rincian teknologi dalam proyek ini:

* **Core Framework:** Flutter (Stable Channel)
* **Bahasa Pemrograman & Modul Penyusun:**
  * **Dart (79.2%):** Bahasa pemrograman utama untuk menyusun seluruh logika bisnis, state management, dan komponen User Interface (UI).
  * **C++ & CMake (18.4%):** Digunakan sebagai jembatan native build sistem, optimasi alokasi memori, serta kompilasi pada ekosistem desktop (Windows dan Linux).
  * **Swift (1.1%):** Berkas native bridge untuk menjamin fungsionalitas berjalan baik di lingkungan iOS.
  * **HTML (0.6%):** Kode entry-point pendukung untuk proses rendering saat dideploy ke platform Web.
* **IDE / Editor:** Visual Studio Code / Android Studio

---

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Struktur Direktori

```text
sipades_mobile/
├── android/          # Konfigurasi native dan build script untuk OS Android
├── ios/              # Konfigurasi native, skema pod, dan hak akses untuk OS iOS
├── lib/              # Source code utama aplikasi (Tempat penulisan kode Dart)
│   └── main.dart     # Entry point / file utama yang pertama kali dieksekusi
├── assets/images/    # Direktori penyimpanan aset gambar, logo, dan ikon lokal
├── windows/          # Konfigurasi native build untuk OS Windows (C++/CMake)
├── linux/            # Konfigurasi native build untuk OS Linux (C++/CMake)
├── macos/            # Konfigurasi native build untuk OS macOS
├── web/              # Berkas konfigurasi web renderer dan manifest web
├── analysis_options.yaml # Aturan linter resmi untuk standarisasi gaya penulisan kode Dart
└── pubspec.yaml      # File konfigurasi dependensi library (package) dan aset proyek

