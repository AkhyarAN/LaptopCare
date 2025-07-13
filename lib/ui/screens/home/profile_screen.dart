import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/reminder_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/guide_provider.dart';
import '../../../data/models/user.dart';
import '../../../services/notification_service.dart';
import '../../../utils/guide_seeder.dart';
import '../../../utils/appwrite_seeder.dart';
import '../../../utils/appwrite_auto_setup.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _darkTheme = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update tema state jika ThemeProvider berubah
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_darkTheme != themeProvider.isDarkMode) {
      setState(() {
        _darkTheme = themeProvider.isDarkMode;
      });
    }
  }

  void _loadUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (user != null) {
      _nameController.text = user.name ?? '';
      _notificationsEnabled = user.notificationsEnabled;
    }

    // Load theme dari ThemeProvider
    _darkTheme = themeProvider.isDarkMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      // Update tema melalui ThemeProvider
      await themeProvider.setDarkTheme(_darkTheme);

      // Update profile user (tanpa tema karena sudah dihandle ThemeProvider)
      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        theme: _darkTheme
            ? 'dark'
            : 'light', // Tetap simpan di user profile untuk backup
        notificationsEnabled: _notificationsEnabled,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);

    // Clear semua data dari provider lain sebelum logout
    debugPrint('Logout: Membersihkan semua data provider');
    laptopProvider.clearData();
    taskProvider.clearData();
    reminderProvider.clearData();

    // Logout dari auth provider
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _populateGuidesData() async {
    try {
      await GuideSeeder.seedGuides();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 10 Panduan berhasil ditambahkan ke database! 📚'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Refresh guides after seeding
        final guideProvider =
            Provider.of<GuideProvider>(context, listen: false);
        await guideProvider.fetchGuides();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error populating guides: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _smartPopulateGuides() async {
    try {
      // Show loading with wait message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                  'Waiting for attributes to be ready...\nThis may take 30-60 seconds.'),
            ],
          ),
        ),
      );

      // Wait for attributes to be fully ready
      bool attributesReady = false;
      int attempts = 0;
      int maxAttempts = 12; // 60 seconds total (5 second intervals)

      while (!attributesReady && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 5));
        attempts++;

        try {
          // Try to seed guides - if it works, attributes are ready
          await GuideSeeder.seedGuides();
          attributesReady = true;

          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '🎉 SUCCESS! 10 Panduan berhasil ditambahkan setelah waiting! 📚'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );

            // Refresh guides after seeding
            final guideProvider =
                Provider.of<GuideProvider>(context, listen: false);
            await guideProvider.fetchGuides();
          }
          break;
        } catch (e) {
          debugPrint('Attempt $attempts failed: $e');
          if (e.toString().contains('Unknown attribute') ||
              e.toString().contains('document_invalid_structure')) {
            // Attributes still not ready, continue waiting
            continue;
          } else {
            // Other error, stop trying
            throw e;
          }
        }
      }

      if (!attributesReady) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⏰ Attributes still processing. Try "Manual Populate Data" in 1-2 minutes.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error during smart populate: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showGuidesCollectionInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Guides Collection'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ikuti langkah berikut untuk membuat collection guides di Appwrite Console:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. Buka Appwrite Console'),
              const Text('2. Pilih project: project-fra-task-management-app'),
              const Text('3. Masuk ke Database > laptopcare-db'),
              const Text('4. Klik "Create Collection"'),
              const Text('5. Nama collection: "guides"'),
              const Text('6. Collection ID: "guides"'),
              const SizedBox(height: 12),
              const Text(
                'Attributes yang harus dibuat:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '• guide_id (String, Required, Size: 255)\n'
                  '• category (String, Required, Size: 100)\n'
                  '• title (String, Required, Size: 255)\n'
                  '• content (String, Required, Size: 10000)\n'
                  '• difficulty (String, Required, Size: 50)\n'
                  '• estimated_time (Integer, Required)\n'
                  '• is_premium (Boolean, Required)\n'
                  '• created_at (String, Required, Size: 50)\n'
                  '• updated_at (String, Required, Size: 50)',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'PENTING - Set Permissions:',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Collection Settings > Permissions:\n'
                  '• Create: Any\n'
                  '• Read: Any\n'
                  '• Update: Any\n'
                  '• Delete: Any',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '7. Klik "Create" untuk menyimpan collection\n'
                '8. Kembali ke app dan klik "Populate Guides Data"',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open browser to Appwrite Console
              // Note: This would need url_launcher package to actually open browser
            },
            child: const Text('Buka Console'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (user.name?.isNotEmpty == true
                    ? user.name![0].toUpperCase()
                    : user.email[0].toUpperCase()),
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(
        child: Text('User not logged in'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile header
        _buildProfileHeader(context, user),
        const SizedBox(height: 24),
        // Settings section
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Theme toggle
                  SwitchListTile(
                    title: const Text('Dark Theme'),
                    subtitle: Text(_darkTheme
                        ? 'Dark mode enabled'
                        : 'Light mode enabled'),
                    value: _darkTheme,
                    onChanged: (value) async {
                      setState(() {
                        _darkTheme = value;
                      });

                      // Langsung update tema tanpa perlu save
                      final themeProvider =
                          Provider.of<ThemeProvider>(context, listen: false);
                      final messenger = ScaffoldMessenger.of(context);

                      await themeProvider.setDarkTheme(value);

                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(value
                                ? 'Switched to dark theme'
                                : 'Switched to light theme'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                  // Notifications toggle
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Save button
                  Center(
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _saveProfile,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Notification Debug Section
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Debugging',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Jika notifikasi tidak muncul pada pukul 00:00, gunakan tools di bawah ini untuk debugging:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Test Notification Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final notificationService = NotificationService();
                    await notificationService.testNotificationNow();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Test notification sent! Check your notification panel.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notification_add),
                  label: const Text('Test Notification Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Check Permissions Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final notificationService = NotificationService();
                    await notificationService.initialize();
                    final hasPermission =
                        await notificationService.requestPermissions();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(hasPermission
                              ? 'Notification permissions granted ✅'
                              : 'Notification permissions denied ❌'),
                          backgroundColor:
                              hasPermission ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Check Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Tips untuk Notifikasi Tengah Malam:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Matikan Battery Optimization untuk LaptopCare\n'
                        '2. Izinkan notifikasi "High Priority"\n'
                        '3. Pastikan mode "Do Not Disturb" tidak aktif\n'
                        '4. Set "Exact Alarm" permission di Android 12+\n'
                        '5. Test notifikasi dengan tombol di atas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Database Setup Section
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Database',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ ATTRIBUTE is_premium SUDAH ADA!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Collection sudah lengkap! Jika panduan masih 0, gunakan "Smart Populate" yang akan wait sampai attribute fully ready (30-60 detik).',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Auto Setup Button (Recommended)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                                'Setting up Guides collection automatically...\nThis may take 30-60 seconds.'),
                          ],
                        ),
                      ),
                    );

                    try {
                      final result = await AppwriteAutoSetup
                          .setupGuidesCollectionAutomatically();

                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog

                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ ${result['message']}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );

                          // Use smart populate instead of immediate populate
                          await Future.delayed(const Duration(seconds: 1));
                          await _smartPopulateGuides();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ ${result['message']}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error during auto-setup: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('🚀 Auto Setup Guides (Recommended)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),

                const SizedBox(height: 12),

                // Manual Check Database Button (fallback)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Checking database collections...'),
                          ],
                        ),
                      ),
                    );

                    try {
                      await AppwriteSeeder.runSeeder(context);
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.storage),
                  label: const Text('Manual Check Collections'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Smart Populate Guides Button (for when attributes are ready)
                ElevatedButton.icon(
                  onPressed: () async {
                    await _smartPopulateGuides();
                  },
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('🤖 Smart Populate (Wait & Retry)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Manual Populate Guides Button (fallback)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Populating guides data...'),
                          ],
                        ),
                      ),
                    );

                    try {
                      await _populateGuidesData();

                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                      }
                    }
                  },
                  icon: const Icon(Icons.library_books),
                  label: const Text('Quick Populate (No Wait)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Manual Add Attribute Instructions
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                            '📝 Manual Fix: Add is_premium Attribute'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  border: Border.all(color: Colors.amber),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'JIKA AUTO FIX GAGAL, LAKUKAN MANUAL:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '1. Buka Appwrite Console di browser\n'
                                      '2. Login dan pilih project "project-fra-task-management-app"\n'
                                      '3. Database > laptopcare-db > Guides collection\n'
                                      '4. Klik tab "Attributes"\n'
                                      '5. Klik "Create attribute" (tombol merah)\n'
                                      '6. Pilih "Boolean"\n'
                                      '7. Isi form:\n'
                                      '   • Key: is_premium\n'
                                      '   • Required: ❌ (JANGAN dicentang)\n'
                                      '   • Default value: false\n'
                                      '8. Klik "Create"\n'
                                      '9. Tunggu sampai attribute muncul di list\n'
                                      '10. Kembali ke app, klik "Manual Populate Data"',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚠️ PENTING:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '• Required harus TIDAK dicentang\n'
                                      '• Default value harus "false"\n'
                                      '• Key harus exactly "is_premium"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Tutup'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK, Paham'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.info),
                  label: const Text('Manual Fix Instructions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Manual Setup Instructions Button
                ElevatedButton.icon(
                  onPressed: _showGuidesCollectionInstructions,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Panduan Setup Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Fix Missing Attributes Button
                ElevatedButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                                'Adding missing attributes...\nThis will fix "is_premium" attribute error.'),
                          ],
                        ),
                      ),
                    );

                    try {
                      final result = await AppwriteAutoSetup
                          .addMissingAttributesToExistingCollection();

                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog

                        if (result['success']) {
                          final addedAttributes =
                              result['addedAttributes'] as List<String>;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ ${result['message']}\nAdded: ${addedAttributes.join(", ")}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );

                          // Wait a bit for attributes to be ready, then use smart populate
                          if (addedAttributes.isNotEmpty) {
                            await Future.delayed(const Duration(seconds: 1));
                            await _smartPopulateGuides();
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ ${result['message']}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error fixing attributes: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.build_circle),
                  label: const Text('🔧 Fix Missing Attributes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // Test Guides Permission Button
                ElevatedButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Testing guides permissions...'),
                          ],
                        ),
                      ),
                    );

                    try {
                      final guideProvider =
                          Provider.of<GuideProvider>(context, listen: false);
                      await guideProvider.fetchGuides();

                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '✅ Permissions OK! Collection bisa diakses'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close loading dialog

                        // Show detailed permission fix instructions
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('⚠️ Permission Error'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Error: $e'),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'LANGKAH PERBAIKAN:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '1. Di Appwrite Console > Guides collection\n'
                                      '2. Klik tab "Settings"\n'
                                      '3. Scroll ke bagian "Permissions"\n'
                                      '4. Untuk setiap permission (Create, Read, Update, Delete):\n'
                                      '   • Klik "Add a role"\n'
                                      '   • Pilih "Any"\n'
                                      '   • Klik "Add"\n'
                                      '5. Klik "Update" untuk save\n'
                                      '6. Test lagi dengan tombol ini',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Test Guides Permission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Setelah Setup Collection:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 10 panduan perawatan komprehensif\n'
                        '• Mencakup Physical, Software, Security & Performance\n'
                        '• Tingkat kesulitan Easy, Medium & Advanced\n'
                        '• Beberapa panduan premium untuk fitur lanjutan\n'
                        '• Tab Panduan akan langsung dapat digunakan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        // Logout button
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
          ),
        ),
        // Error message
        if (authProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              authProvider.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
