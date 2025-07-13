Nama  : Akhyar Nurullah
NIM   : 221240001339
Kelas : DB


# LaptopCare - Aplikasi Pemeliharaan Laptop

Aplikasi Flutter untuk membantu pengguna melacak dan mengelola pemeliharaan laptop mereka.

## Fitur

### Fitur Utama
- **Manajemen Laptop**: Kelola profil multiple laptop dengan foto dan spesifikasi lengkap
- **Tugas Pemeliharaan**: Penjadwalan dan tracking tugas perawatan berdasarkan kategori
- **Sistem Pengingat**: Notifikasi otomatis untuk tugas pemeliharaan yang akan datang
- **Panduan Perawatan**: Koleksi panduan komprehensif untuk semua aspek perawatan laptop
- **Statistik & Riwayat**: Analytics dan visualisasi data pemeliharaan
- **Dark/Light Theme**: Switch tema sesuai preferensi pengguna

### Fitur Lanjutan (Iterasi 4)
- **Panduan Perawatan Komprehensif**: 10+ panduan detail untuk Physical, Software, Security & Performance
- **Filter & Search**: Cari dan filter panduan berdasarkan kategori, kesulitan, dan status premium
- **Statistik Dashboard**: Overview pemeliharaan dengan metrics bulanan dan mingguan
- **Export Capabilities**: Export data riwayat (fitur premium)
- **Premium Content**: Panduan advanced untuk users premium

## Persyaratan

- Flutter SDK
- Appwrite Backend

## Konfigurasi Appwrite

Aplikasi ini menggunakan Appwrite sebagai backend. Anda dapat mengatur koleksi database Appwrite secara otomatis menggunakan script yang disediakan.

### Mengatur Appwrite Backend secara Manual

1. Buat project di [Appwrite Console](https://cloud.appwrite.io/)
2. Buat database dengan ID `laptopcare-db`
3. Buat koleksi-koleksi berikut:
   - `users`
   - `laptops`
   - `maintenance_tasks`
   - `maintenance_history`
   - `reminders`
4. Buat bucket storage dengan ID `laptopcare-storage`

### Mengatur Appwrite Backend secara Otomatis

Anda dapat menggunakan script yang disediakan untuk membuat semua koleksi dan atribut yang diperlukan secara otomatis.

#### Untuk pengguna Linux/macOS:

1. Buat project di [Appwrite Console](https://cloud.appwrite.io/) dengan ID `task-management-app`
2. Dapatkan API key dengan izin yang sesuai (minimal izin untuk database dan storage)
3. Buka terminal dan navigasikan ke direktori project
4. Berikan izin eksekusi pada script:
   ```bash
   chmod +x appwrite_setup.sh
   ```
5. Jalankan script:
   ```bash
   ./appwrite_setup.sh
   ```

#### Untuk pengguna Windows:

1. Buat project di [Appwrite Console](https://cloud.appwrite.io/) dengan ID `task-management-app`
2. Dapatkan API key dengan izin yang sesuai (minimal izin untuk database dan storage)
3. Buka PowerShell dan navigasikan ke direktori project
4. Jalankan script:
   ```powershell
   .\appwrite_setup.ps1
   ```

Script akan:
- Menginstal Appwrite CLI jika belum terinstal
- Login ke Appwrite menggunakan API key yang disediakan
- Membuat database `laptopcare-db`
- Membuat semua koleksi yang diperlukan dengan atribut yang sesuai
- Membuat bucket storage

## Menjalankan Aplikasi

1. Clone repository
2. Instal dependensi:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## Setup Panduan Perawatan (Iterasi 4)

Setelah aplikasi berjalan, untuk mendapatkan akses ke panduan perawatan komprehensif:

1. **Login** ke aplikasi dengan akun Anda
2. **Navigasi** ke tab "Profile" (ikon person di bottom navigation)
3. **Scroll** ke bagian "Setup Panduan"
4. **Klik** tombol "Setup Panduan Database"
5. **Tunggu** proses seeding selesai (akan muncul notifikasi sukses)
6. **Navigasi** ke tab "Panduan" untuk melihat semua panduan yang tersedia

### Panduan yang Tersedia

**Physical Maintenance (3 panduan):**
- Cara Membersihkan Layar Laptop (Easy, 10 menit)
- Membersihkan Keyboard dan Touchpad (Easy, 15 menit)
- Membersihkan Ventilasi dan Fan Laptop (Advanced, 45 menit) *Premium*

**Software Maintenance (2 panduan):**
- Cara Melakukan Disk Cleanup (Easy, 20 menit)
- Update Driver dan Software (Medium, 30 menit)

**Security (2 panduan):**
- Scan Virus dan Malware (Medium, 60 menit)
- Backup Data Penting (Medium, 45 menit) *Premium*

**Performance (3 panduan):**
- Optimasi Startup Programs (Easy, 15 menit)
- Defragmentasi Hard Drive (Medium, 180 menit) *Premium*
- Monitor Temperature dan Performance (Medium, 25 menit)

### Fitur Panduan

- **Search & Filter**: Cari panduan berdasarkan keyword, filter berdasarkan kategori, tingkat kesulitan
- **Detailed Content**: Setiap panduan memiliki langkah-langkah detail dengan tips dan peringatan
- **Difficulty Levels**: Easy (hijau), Medium (orange), Advanced (merah)
- **Time Estimates**: Estimasi waktu pengerjaan untuk setiap panduan
- **Premium Content**: Beberapa panduan advanced memerlukan upgrade premium
- **Copy & Share**: Copy panduan ke clipboard atau share (fitur akan datang)

## Menggunakan Statistik & Riwayat

Tab "Statistik" menyediakan:

- **Overview Cards**: Total perawatan, perawatan bulan ini, minggu ini, dan jumlah laptop aktif
- **Breakdown per Laptop**: Statistik perawatan untuk setiap laptop
- **Riwayat Terkini**: 10 aktivitas perawatan terakhir
- **Filter Riwayat**: Filter berdasarkan laptop dan rentang tanggal

### Tips Menggunakan Aplikasi

1. **Setup Database**: Pastikan menggunakan tombol "Setup Database" di Profile jika ada error permissions
2. **Populate Guides**: Jalankan "Setup Panduan Database" untuk mendapatkan panduan lengkap
3. **Dark Theme**: Toggle theme di Profile Settings untuk kenyamanan mata
4. **Notifications**: Aktifkan notifikasi dan gunakan debug tools jika ada masalah
5. **Multiple Laptops**: Tambahkan semua laptop Anda untuk tracking yang komprehensif

## Struktur Koleksi Database

### Koleksi Users
- `user_id` (String): ID pengguna
- `email` (String): Email pengguna
- `name` (String): Nama pengguna
- `theme` (String): Tema UI yang dipilih
- `notifications_enabled` (Boolean): Status notifikasi
- `created_at` (DateTime): Waktu pembuatan akun
- `last_login` (DateTime): Waktu login terakhir

### Koleksi Laptops
- `laptop_id` (String): ID laptop
- `user_id` (String): ID pemilik laptop
- `name` (String): Nama laptop
- `brand` (String): Merek laptop
- `model` (String): Model laptop
- `os` (String): Sistem operasi
- `ram` (String): Kapasitas RAM
- `storage` (String): Kapasitas penyimpanan
- `cpu` (String): Prosesor
- `gpu` (String): Kartu grafis
- `image_id` (String): ID gambar laptop
- `purchase_date` (String): Tanggal pembelian
- `created_at` (DateTime): Waktu penambahan laptop
- `updated_at` (DateTime): Waktu pembaruan terakhir

### Koleksi Maintenance Tasks
- `task_id` (String): ID tugas
- `user_id` (String): ID pemilik tugas
- `laptop_id` (String): ID laptop terkait
- `title` (String): Judul tugas
- `description` (String): Deskripsi tugas
- `category` (String): Kategori tugas (physical, software, security, performance)
- `frequency` (String): Frekuensi tugas (daily, weekly, monthly, quarterly)
- `priority` (String): Prioritas tugas (low, medium, high)
- `created_at` (DateTime): Waktu pembuatan tugas
- `updated_at` (DateTime): Waktu pembaruan terakhir

### Koleksi Maintenance History
- `history_id` (String): ID riwayat
- `user_id` (String): ID pengguna
- `laptop_id` (String): ID laptop
- `task_id` (String): ID tugas
- `completion_date` (DateTime): Tanggal penyelesaian
- `notes` (String): Catatan
- `created_at` (DateTime): Waktu pencatatan

### Koleksi Reminders
- `reminder_id` (String): ID pengingat
- `user_id` (String): ID pengguna
- `laptop_id` (String): ID laptop
- `task_id` (String): ID tugas
- `status` (String): Status pengingat (pending, completed, dismissed)
- `frequency` (String): Frekuensi pengingat
- `scheduled_date` (DateTime): Tanggal terjadwal
- `created_at` (DateTime): Waktu pembuatan
- `updated_at` (DateTime): Waktu pembaruan terakhir

### Koleksi Guides (Iterasi 4)
- `guide_id` (String): ID panduan
- `category` (String): Kategori panduan (physical, software, security, performance)
- `title` (String): Judul panduan
- `content` (String): Konten lengkap panduan
- `difficulty` (String): Tingkat kesulitan (easy, medium, advanced)
- `estimated_time` (Integer): Estimasi waktu dalam menit
- `is_premium` (Boolean): Status konten premium
- `created_at` (DateTime): Waktu pembuatan
- `updated_at` (DateTime): Waktu pembaruan terakhir

