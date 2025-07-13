import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../data/models/guide.dart';
import '../../../data/models/maintenance_task.dart';
import 'package:flutter/services.dart';
import 'premium_upgrade_screen.dart';

class GuideDetailScreen extends StatefulWidget {
  final Guide guide;

  const GuideDetailScreen({
    super.key,
    required this.guide,
  });

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  bool _isFavorited = false;

  Color _getDifficultyColor(GuideDifficulty difficulty) {
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

  void _shareGuide() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur share akan segera tersedia'),
      ),
    );
  }

  void _copyToClipboard() {
    final content = """
${widget.guide.title}

Kategori: ${widget.guide.category.name}
Tingkat Kesulitan: ${widget.guide.difficulty.name}
Estimasi Waktu: ${widget.guide.estimatedTime} menit

${widget.guide.content}
""";

    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panduan disalin ke clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Block premium content access - redirect to upgrade screen
    if (widget.guide.isPremium) {
      return PremiumUpgradeScreen(
        title: widget.guide.title,
        description: 'This advanced guide requires Premium access.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.guide.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorited
                        ? 'Ditambahkan ke favorit'
                        : 'Dihapus dari favorit',
                  ),
                ),
              );
            },
            tooltip: 'Favorit',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareGuide();
                  break;
                case 'copy':
                  _copyToClipboard();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 12),
                    Text('Bagikan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 12),
                    Text('Salin'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Premium Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.guide.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (widget.guide.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category and Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(widget.guide.category),
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kategori',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                widget.guide.category.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Details Row
                    Row(
                      children: [
                        // Difficulty
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _getDifficultyColor(widget.guide.difficulty)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getDifficultyColor(
                                    widget.guide.difficulty),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: _getDifficultyColor(
                                      widget.guide.difficulty),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kesulitan',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  widget.guide.difficulty.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getDifficultyColor(
                                        widget.guide.difficulty),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Estimated Time
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Estimasi Waktu',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${widget.guide.estimatedTime} menit',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.article,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Panduan Lengkap',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content with proper formatting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.guide.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Warning Card for Premium content
            if (widget.guide.isPremium)
              Card(
                color: Colors.amber.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Konten Premium',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Panduan ini tersedia untuk pengguna premium. Upgrade untuk mengakses semua fitur.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Timestamps
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dibuat: ${widget.guide.createdAt.day}/${widget.guide.createdAt.month}/${widget.guide.createdAt.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.update,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Diperbarui: ${widget.guide.updatedAt.day}/${widget.guide.updatedAt.month}/${widget.guide.updatedAt.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
