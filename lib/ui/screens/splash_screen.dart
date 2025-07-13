import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();

    // Update status after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _statusText = 'Loading app data...';
        });
      }
    });

    // Update status again after another delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _statusText = 'Almost ready...';
        });
      }
    });

    // Auto-navigate to login after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isNavigating) {
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    if (mounted && !_isNavigating) {
      setState(() {
        _isNavigating = true;
        _statusText = 'Navigating to login...';
      });

      debugPrint('📝 Navigating to login...');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.laptop_mac,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                Text(
                  'LaptopCare',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),

                const SizedBox(height: 12),

                // App Tagline
                Text(
                  'Maintain your laptop with ease',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Simple loading indicator
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status text
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),

                const SizedBox(height: 32),

                // Big, prominent login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isNavigating ? null : _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isNavigating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Go to Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Or wait 3 seconds for auto-redirect',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Version info
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
