import 'package:flutter/material.dart';

class PremiumUpgradeScreen extends StatelessWidget {
  final String title;
  final String? description;

  const PremiumUpgradeScreen({
    super.key,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Required'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.amber,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock,
                size: 60,
                color: Colors.amber,
              ),
            ),

            const SizedBox(height: 32),

            // Premium Required Title
            Text(
              'Premium Content',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Guide Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Text(
              'Panduan ini tersedia khusus untuk pengguna Premium. Upgrade ke Premium untuk mengakses semua panduan advanced dan fitur eksklusif lainnya.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Premium Benefits
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.orange.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '✨ Premium Benefits',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                  ),
                  const SizedBox(height: 16),
                  const _BenefitItem(
                    icon: Icons.library_books,
                    title: 'Advanced Guides',
                    description: 'Akses semua panduan tingkat lanjut',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitItem(
                    icon: Icons.settings,
                    title: 'Extended Features',
                    description: 'Fitur-fitur canggih untuk maintenance',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitItem(
                    icon: Icons.priority_high,
                    title: 'Priority Support',
                    description: 'Dukungan prioritas 24/7',
                  ),
                  const SizedBox(height: 12),
                  const _BenefitItem(
                    icon: Icons.cloud_sync,
                    title: 'Cloud Sync',
                    description: 'Sinkronisasi data ke cloud',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showUpgradeOptions(context);
                },
                icon: const Icon(Icons.star),
                label: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Maybe Later Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const PremiumUpgradeBottomSheet(),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.amber[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PremiumUpgradeBottomSheet extends StatelessWidget {
  const PremiumUpgradeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 24),

          // Monthly Plan
          _PremiumPlanCard(
            title: 'Monthly Premium',
            price: 'Rp 29.000',
            period: '/month',
            features: const [
              'All Premium Guides',
              'Advanced Features',
              'Priority Support',
              'Cloud Sync',
            ],
            isPopular: false,
            onTap: () => _selectPlan(context, 'monthly'),
          ),

          const SizedBox(height: 16),

          // Yearly Plan
          _PremiumPlanCard(
            title: 'Yearly Premium',
            price: 'Rp 299.000',
            period: '/year',
            originalPrice: 'Rp 348.000',
            features: const [
              'All Monthly Benefits',
              'Save 14% per year',
              'Exclusive yearly content',
              'Early access to new features',
            ],
            isPopular: true,
            onTap: () => _selectPlan(context, 'yearly'),
          ),

          const SizedBox(height: 24),

          Text(
            'Cancel anytime. No hidden fees.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _selectPlan(BuildContext context, String plan) {
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Premium $plan plan selected! Feature coming soon.'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? originalPrice;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onTap;

  const _PremiumPlanCard({
    required this.title,
    required this.price,
    required this.period,
    this.originalPrice,
    required this.features,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isPopular ? Colors.amber : Theme.of(context).colorScheme.outline,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'POPULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                    ),
                    Text(
                      period,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (originalPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        originalPrice!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 