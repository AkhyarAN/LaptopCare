import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import '../data/services/appwrite_service.dart';
import '../data/models/guide.dart';
import '../data/models/maintenance_task.dart';

class GuideSeeder {
  static final AppwriteService _appwriteService = AppwriteService();

  static Future<void> seedGuides() async {
    try {
      debugPrint('GuideSeeder: Starting guide seeding...');

      final guides = _getGuideData();

      for (final guide in guides) {
        try {
          await _createGuideInAppwrite(guide);
          debugPrint('GuideSeeder: Created guide: ${guide.title}');
        } catch (e) {
          debugPrint('GuideSeeder: Error creating guide ${guide.title}: $e');
        }
      }

      debugPrint('GuideSeeder: Seeding completed');
    } catch (e) {
      debugPrint('GuideSeeder: Error during seeding: $e');
      rethrow;
    }
  }

  static Future<void> _createGuideInAppwrite(Guide guide) async {
    try {
      await _appwriteService.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.guidesCollectionId,
        documentId: guide.guideId,
        data: guide.toJson(),
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.any()),
          Permission.update(Role.any()),
          Permission.delete(Role.any()),
        ],
      );
    } catch (e) {
      rethrow;
    }
  }

  static List<Guide> _getGuideData() {
    final now = DateTime.now();

    return [
      // Physical Maintenance Guides
      Guide(
        guideId: 'guide-001',
        category: TaskCategory.physical,
        title: 'Cara Membersihkan Layar Laptop',
        content: '''
1. Matikan laptop dan cabut charger
2. Siapkan kain microfiber dan cairan pembersih layar khusus
3. Semprotkan cairan ke kain, bukan langsung ke layar
4. Bersihkan layar dengan gerakan melingkar lembut
5. Gunakan kain kering untuk mengelap sisa cairan
6. Biarkan kering sepenuhnya sebelum menutup laptop

Tips:
- Jangan gunakan cairan berbasis alkohol atau amonia
- Hindari menekan layar terlalu keras
- Bersihkan layar minimal 1-2 kali seminggu
        ''',
        difficulty: GuideDifficulty.easy,
        estimatedTime: 10,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),

      Guide(
        guideId: 'guide-002',
        category: TaskCategory.physical,
        title: 'Membersihkan Keyboard dan Touchpad',
        content: '''
1. Matikan laptop dan cabut semua kabel
2. Balik laptop dan goyangkan perlahan untuk mengeluarkan debu
3. Gunakan compressed air untuk meniup sela-sela tombol
4. Basahi cotton bud dengan isopropyl alcohol 70%
5. Bersihkan setiap tombol dengan cotton bud
6. Gunakan kain microfiber untuk membersihkan touchpad
7. Pastikan semua kering sebelum menyalakan kembali

Peringatan:
- Jangan gunakan air berlebihan
- Hindari cairan masuk ke dalam keyboard
- Gunakan tekanan ringan saat membersihkan
        ''',
        difficulty: GuideDifficulty.easy,
        estimatedTime: 15,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),

      Guide(
        guideId: 'guide-003',
        category: TaskCategory.physical,
        title: 'Membersihkan Ventilasi dan Fan Laptop',
        content: '''
1. Matikan laptop dan lepas semua kabel
2. Lepas baterai jika memungkinkan
3. Buka panel belakang dengan hati-hati
4. Gunakan compressed air untuk meniup debu dari fan
5. Bersihkan heatsink dengan kuas halus
6. Gunakan cotton bud untuk area yang sempit
7. Pastikan fan berputar bebas setelah dibersihkan
8. Pasang kembali semua komponen dengan benar

Alat yang dibutuhkan:
- Obeng sesuai jenis sekrup laptop
- Compressed air
- Kuas halus
- Cotton bud
- Thermal paste (jika diperlukan)

PERINGATAN: Proses ini memerlukan keahlian teknis!
        ''',
        difficulty: GuideDifficulty.advanced,
        estimatedTime: 45,
        isPremium: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Software Maintenance Guides
      Guide(
        guideId: 'guide-004',
        category: TaskCategory.software,
        title: 'Cara Melakukan Disk Cleanup',
        content: '''
Windows 10/11:
1. Tekan Windows + R, ketik "cleanmgr"
2. Pilih drive C: (atau drive sistem utama)
3. Tunggu proses scanning selesai
4. Centang semua file yang ingin dihapus:
   - Temporary files
   - Recycle Bin
   - System error memory dump files
   - Windows Update Cleanup
5. Klik OK dan konfirmasi penghapusan
6. Restart laptop setelah selesai

Menggunakan Storage Sense:
1. Buka Settings > System > Storage
2. Klik "Configure Storage Sense"
3. Aktifkan "Storage Sense"
4. Atur jadwal pembersihan otomatis
5. Klik "Clean now" untuk pembersihan manual

Manfaat:
- Membebaskan ruang penyimpanan
- Meningkatkan performa sistem
- Mengurangi file sampah
        ''',
        difficulty: GuideDifficulty.easy,
        estimatedTime: 20,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),

      Guide(
        guideId: 'guide-005',
        category: TaskCategory.software,
        title: 'Update Driver dan Software',
        content: '''
Update Driver:
1. Klik kanan "This PC" > Properties > Device Manager
2. Cari device dengan tanda seru kuning
3. Klik kanan device > Update driver
4. Pilih "Search automatically for drivers"
5. Tunggu proses download dan install

Menggunakan Windows Update:
1. Buka Settings > Update & Security
2. Klik "Check for updates"
3. Install semua update yang tersedia
4. Restart jika diminta

Update Driver GPU:
- NVIDIA: Download GeForce Experience
- AMD: Download AMD Radeon Software
- Intel: Download Intel Driver & Support Assistant

Software Penting untuk Update:
- Browser (Chrome, Firefox, Edge)
- Antivirus
- Adobe Reader
- Media player (VLC)
- Office suite

Tips:
- Update driver secara berkala
- Backup driver sebelum update
- Cek compatibility sebelum update major
        ''',
        difficulty: GuideDifficulty.medium,
        estimatedTime: 30,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),

      // Security Guides
      Guide(
        guideId: 'guide-006',
        category: TaskCategory.security,
        title: 'Scan Virus dan Malware',
        content: '''
Menggunakan Windows Defender:
1. Buka Windows Security (Windows + S, ketik "Windows Security")
2. Pilih "Virus & threat protection"
3. Klik "Quick scan" untuk scan cepat
4. Atau pilih "Scan options" untuk full scan
5. Tunggu proses scan selesai
6. Ikuti rekomendasi untuk file yang terdeteksi

Menggunakan Malwarebytes:
1. Download dan install Malwarebytes
2. Update database virus terbaru
3. Pilih "Scan" > "Threat Scan"
4. Tunggu scan selesai
5. Quarantine atau hapus threat yang ditemukan

Best Practice:
- Scan mingguan dengan Windows Defender
- Scan bulanan dengan anti-malware tambahan
- Aktifkan real-time protection
- Jangan download dari sumber tidak terpercaya
- Update antivirus secara otomatis

Tanda-tanda Infeksi:
- Laptop lambat tiba-tiba
- Pop-up iklan berlebihan
- Homepage browser berubah
- File hilang atau corrupt
- Aktivitas jaringan mencurigakan
        ''',
        difficulty: GuideDifficulty.medium,
        estimatedTime: 60,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),

      Guide(
        guideId: 'guide-007',
        category: TaskCategory.security,
        title: 'Backup Data Penting',
        content: '''
Metode Backup Local:
1. Siapkan external hard drive atau USB
2. Identifikasi file penting:
   - Dokumen pribadi
   - Foto dan video
   - File kerja/sekolah
   - Bookmark browser
   - Email dan kontak
3. Copy manual atau gunakan sync software
4. Verifikasi integritas backup
5. Simpan external drive di tempat aman

Menggunakan File History (Windows):
1. Buka Settings > Update & Security > Backup
2. Connect external drive
3. Klik "Add a drive" dan pilih external drive
4. Aktifkan "Automatically back up my files"
5. Klik "More options" untuk pengaturan detail

Cloud Backup:
- Google Drive (15GB gratis)
- OneDrive (5GB gratis)
- Dropbox (2GB gratis)
- iCloud (untuk pengguna Apple)

Strategi 3-2-1:
- 3 salinan data (original + 2 backup)
- 2 media berbeda (local + cloud)
- 1 backup offsite (cloud atau lokasi lain)

Jadwal Backup:
- Harian: File kerja penting
- Mingguan: Semua dokumen
- Bulanan: Full system backup
        ''',
        difficulty: GuideDifficulty.medium,
        estimatedTime: 45,
        isPremium: true,
        createdAt: now,
        updatedAt: now,
      ),

      // Performance Guides
      Guide(
        guideId: 'guide-008',
        category: TaskCategory.performance,
        title: 'Optimasi Startup Programs',
        content: '''
Menggunakan Task Manager:
1. Tekan Ctrl + Shift + Esc
2. Klik tab "Startup"
3. Lihat kolom "Startup impact"
4. Klik kanan program dengan "High impact"
5. Pilih "Disable" untuk program yang tidak perlu

Program yang Aman di-Disable:
- Spotify, iTunes (bisa dibuka manual)
- Adobe Updater
- Microsoft Teams (kecuali untuk kerja)
- Game launcher (Steam, Epic, etc.)
- Software editing foto/video

Program yang JANGAN di-Disable:
- Windows Security
- Audio driver
- Touchpad/mouse software
- VPN software (jika digunakan)
- Software antivirus

Menggunakan Settings:
1. Buka Settings > Apps > Startup
2. Toggle OFF untuk app yang tidak perlu
3. Restart laptop untuk melihat efeknya

Tips Optimasi:
- Disable hanya program yang dikenal
- Monitor performa setelah perubahan
- Re-enable jika ada masalah
- Update program secara berkala
        ''',
        difficulty: GuideDifficulty.easy,
        estimatedTime: 15,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),

      Guide(
        guideId: 'guide-009',
        category: TaskCategory.performance,
        title: 'Defragmentasi Hard Drive',
        content: '''
Cek Jenis Storage:
1. Buka "This PC"
2. Klik kanan drive C: > Properties
3. Tab "Tools" > klik "Optimize"
4. Lihat "Media type":
   - HDD: Perlu defragmentasi
   - SSD: Gunakan TRIM, bukan defrag

Untuk Hard Drive (HDD):
1. Buka "Defragment and Optimize Drives"
2. Pilih drive yang ingin di-defrag
3. Klik "Analyze" untuk cek fragmentasi
4. Jika >10% fragmented, klik "Optimize"
5. Tunggu proses selesai (bisa 1-3 jam)

Untuk SSD:
1. Gunakan fitur "Optimize" (TRIM)
2. JANGAN defragmentasi SSD
3. Pastikan TRIM enabled:
   - Buka Command Prompt as admin
   - Ketik: fsutil behavior query DisableDeleteNotify
   - Hasil 0 = TRIM aktif

Jadwal Otomatis:
1. Di Optimize Drives, klik "Change settings"
2. Centang "Run on a schedule"
3. Pilih frequency (Weekly untuk HDD)
4. Pilih drives yang akan di-optimize

Tips:
- Backup data sebelum defrag
- Jangan gunakan laptop saat defrag
- SSD modern tidak perlu defrag manual
        ''',
        difficulty: GuideDifficulty.medium,
        estimatedTime: 180,
        isPremium: true,
        createdAt: now,
        updatedAt: now,
      ),

      Guide(
        guideId: 'guide-010',
        category: TaskCategory.performance,
        title: 'Monitor Temperature dan Performance',
        content: '''
Tools Monitoring:
1. HWiNFO64 (gratis, comprehensive)
2. Core Temp (untuk CPU temperature)
3. GPU-Z (untuk graphics card)
4. CrystalDiskInfo (untuk storage health)

Temperature Normal:
- CPU idle: 30-50°C
- CPU load: 60-80°C
- GPU idle: 30-40°C
- GPU load: 60-85°C
- HDD: <50°C
- SSD: <70°C

Cara Monitoring:
1. Download dan install HWiNFO64
2. Run dalam mode "Sensors-only"
3. Monitor temperature saat:
   - Idle (tidak ada aktivitas)
   - Normal usage (browsing, office)
   - Heavy load (gaming, rendering)

Tanda Overheating:
- Laptop panas berlebihan
- Fan berisik terus-menerus
- Performance turun (throttling)
- Shutdown mendadak
- Blue screen errors

Solusi Overheating:
1. Bersihkan ventilasi dan fan
2. Gunakan laptop cooler pad
3. Tutup program yang tidak perlu
4. Gunakan di permukaan keras dan rata
5. Ganti thermal paste (advanced)

Performance Monitoring:
- Task Manager > Performance tab
- Resource Monitor (resmon.exe)
- Event Viewer untuk system errors
        ''',
        difficulty: GuideDifficulty.medium,
        estimatedTime: 25,
        isPremium: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
 