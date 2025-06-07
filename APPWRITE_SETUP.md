# Panduan Pengaturan Appwrite untuk LaptopCare

Dokumen ini menjelaskan cara mengatur backend Appwrite untuk aplikasi LaptopCare menggunakan Appwrite CLI.

## Persyaratan

- Akun Appwrite
- Appwrite CLI (akan diinstal otomatis oleh script)
- Bash (untuk Linux/macOS) atau PowerShell (untuk Windows)

## Langkah 1: Buat Project di Appwrite Console

1. Buka [Appwrite Console](https://cloud.appwrite.io/)
2. Buat project baru dengan ID `task-management-app`
3. Catat endpoint API (biasanya `https://fra.cloud.appwrite.io/v1`)

## Langkah 2: Buat API Key

1. Di Appwrite Console, buka project Anda
2. Pilih menu "API Keys" di sidebar
3. Klik "Create API Key"
4. Berikan nama untuk API key, misalnya "LaptopCare Setup"
5. Berikan izin berikut:
   - `databases.read`
   - `databases.write`
   - `databases.collections.read`
   - `databases.collections.write`
   - `databases.attributes.read`
   - `databases.attributes.write`
   - `storage.read`
   - `storage.write`
   - `storage.buckets.read`
   - `storage.buckets.write`
6. Klik "Create" dan salin API key yang dihasilkan

## Langkah 3: Jalankan Script Setup

### Untuk Pengguna Windows

1. Buka PowerShell dan navigasikan ke direktori project
2. Jalankan script:
   ```powershell
   .\appwrite_setup.ps1
   ```

## Apa yang Dilakukan Script

Script akan melakukan hal-hal berikut:

1. Menginstal Appwrite CLI jika belum terinstal
2. Login ke Appwrite menggunakan API key yang disediakan
3. Membuat database dengan ID `laptopcare-db`
4. Membuat koleksi-koleksi berikut dengan atribut yang sesuai:
   - `users` - untuk data pengguna
   - `laptops` - untuk data laptop
   - `maintenance_tasks` - untuk tugas pemeliharaan
   - `maintenance_history` - untuk riwayat pemeliharaan
   - `reminders` - untuk pengingat
5. Membuat bucket storage dengan ID `laptopcare-storage` untuk menyimpan gambar

## Memverifikasi Pengaturan

Setelah script selesai dijalankan, Anda dapat memverifikasi pengaturan dengan cara berikut:

1. Buka Appwrite Console
2. Pilih project `task-management-app`
3. Buka menu "Databases" dan periksa apakah database `laptopcare-db` telah dibuat
4. Periksa apakah semua koleksi dan atribut telah dibuat dengan benar
5. Buka menu "Storage" dan periksa apakah bucket `laptopcare-storage` telah dibuat

## Menjalankan Aplikasi

Setelah pengaturan Appwrite selesai, Anda dapat menjalankan aplikasi LaptopCare:

```bash
flutter run
```

## Pemecahan Masalah

Jika Anda mengalami masalah saat menjalankan script, periksa hal-hal berikut:

1. Pastikan API key memiliki izin yang cukup
2. Pastikan ID project dan endpoint API sudah benar
3. Periksa log untuk pesan error spesifik

Jika script gagal membuat salah satu koleksi atau atribut, Anda dapat mencoba menjalankan script lagi. Script dirancang untuk melewati langkah yang sudah berhasil dilakukan sebelumnya.

## Membuat Koleksi Secara Manual

Jika Anda lebih suka membuat koleksi secara manual, Anda dapat menggunakan Appwrite Console:

1. Buka Appwrite Console
2. Pilih project `task-management-app`
3. Buka menu "Databases"
4. Buat database baru dengan ID `laptopcare-db`
5. Buat koleksi-koleksi yang diperlukan dengan atribut yang sesuai
6. Buat bucket storage dengan ID `laptopcare-storage`

Untuk detail tentang atribut yang diperlukan untuk setiap koleksi, lihat file README.md.

## Mengubah Konfigurasi

Jika Anda ingin menggunakan ID project atau database yang berbeda, Anda perlu mengubah konstanta di file berikut:

1. `lib/data/services/appwrite_service.dart` - untuk mengubah ID project, database, dan koleksi
2. `appwrite_setup.sh` atau `appwrite_setup.ps1` - untuk mengubah ID project, database, dan koleksi yang akan dibuat oleh script

## Dukungan

Jika Anda memerlukan bantuan lebih lanjut, silakan buka issue di repository GitHub atau hubungi tim pengembang. 