import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../../data/providers/guide_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/guide.dart';
import '../../../data/models/maintenance_task.dart';
import 'guide_detail_screen.dart';
import 'premium_upgrade_screen.dart';

class GuideListScreen extends StatefulWidget {
  const GuideListScreen({super.key});

  @override
  State<GuideListScreen> createState() => _GuideListScreenState();
}

class _GuideListScreenState extends State<GuideListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGuides();
    });
  }

  void _fetchGuides() {
    final guideProvider = Provider.of<GuideProvider>(context, listen: false);
    guideProvider.fetchGuides();
  }

  List<Guide> _filterGuides(List<Guide> guides) {
    if (_searchQuery.isEmpty) return guides;

    return guides.where((guide) {
      final searchLower = _searchQuery.toLowerCase();
      return guide.title.toLowerCase().contains(searchLower) ||
          guide.content.toLowerCase().contains(searchLower) ||
          guide.category.name.toLowerCase().contains(searchLower);
    }).toList();
  }

  void _showFilterDialog() {
    final guideProvider = Provider.of<GuideProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Panduan'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Filter
                DropdownButtonFormField<TaskCategory?>(
                  value: guideProvider.selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<TaskCategory?>(
                      value: null,
                      child: Text('Semua Kategori'),
                    ),
                    ...TaskCategory.values.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Difficulty Filter
                DropdownButtonFormField<GuideDifficulty?>(
                  value: guideProvider.selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Tingkat Kesulitan',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<GuideDifficulty?>(
                      value: null,
                      child: Text('Semua Tingkat'),
                    ),
                    ...GuideDifficulty.values.map(
                      (difficulty) => DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),

                // Premium Filter
                CheckboxListTile(
                  title: const Text('Hanya Premium'),
                  value: guideProvider.showPremiumOnly,
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              guideProvider.clearFilters();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filters - filter sudah terupdate secara realtime
              Navigator.of(context).pop();
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Perawatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGuides,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari panduan...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Guide List
          Expanded(
            child: Consumer<GuideProvider>(
              builder: (context, guideProvider, child) {
                if (guideProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (guideProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error memuat panduan',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          guideProvider.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchGuides,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final guides = _filterGuides(guideProvider.filteredGuides);

                if (guides.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada panduan ditemukan',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba ubah filter atau kata kunci pencarian',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: guides.length,
                  itemBuilder: (context, index) {
                    final guide = guides[index];
                    return _GuideCard(
                      guide: guide,
                      onTap: () {
                        // Check if guide is premium and block access
                        if (guide.isPremium) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PremiumUpgradeScreen(
                                title: guide.title,
                                description:
                                    'This advanced guide requires Premium access.',
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GuideDetailScreen(guide: guide),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _GuideCard extends StatelessWidget {
  final Guide guide;
  final VoidCallback onTap;

  const _GuideCard({
    required this.guide,
    required this.onTap,
  });

  Color _getDifficultyColor(BuildContext context, GuideDifficulty difficulty) {
    switch (difficulty) {
      case GuideDifficulty.easy:
        return Colors.green;
      case GuideDifficulty.medium:
        return Colors.orange;
      case GuideDifficulty.advanced:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.physical:
        return Icons.hardware;
      case TaskCategory.software:
        return Icons.computer;
      case TaskCategory.security:
        return Icons.security;
      case TaskCategory.performance:
        return Icons.speed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: guide.isPremium ? 4 : 1,
      color: guide.isPremium ? Colors.amber.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: guide.isPremium
            ? BorderSide(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(guide.category),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guide.category.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Premium Badge with Lock
                  if (guide.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 10,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Content Preview with Premium Protection
              Stack(
                children: [
                  Text(
                    guide.isPremium
                        ? 'This is a premium guide with advanced maintenance techniques. Upgrade to Premium to access detailed step-by-step instructions and expert tips...'
                        : guide.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: guide.isPremium
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.6)
                              : null,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (guide.isPremium)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.8),
                              Theme.of(context).colorScheme.surface,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Premium Required',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  // Difficulty
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(context, guide.difficulty)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getDifficultyColor(context, guide.difficulty),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      guide.difficulty.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getDifficultyColor(context, guide.difficulty),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Estimated Time
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${guide.estimatedTime} menit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),

                  const Spacer(),

                  // Arrow or Lock Icon
                  guide.isPremium
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.amber,
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
