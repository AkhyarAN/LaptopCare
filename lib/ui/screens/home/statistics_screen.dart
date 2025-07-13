import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/history_provider.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/laptop_provider.dart';
import '../../../data/models/maintenance_history.dart';
import '../../../data/models/laptop.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLaptopId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  void _fetchHistory() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      historyProvider.fetchHistory(authProvider.currentUser!.id);
    }
  }

  void _showFilterDialog() {
    final laptopProvider = Provider.of<LaptopProvider>(context, listen: false);
    final historyProvider =
        Provider.of<HistoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Riwayat'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Laptop Filter
                DropdownButtonFormField<String?>(
                  value: _selectedLaptopId,
                  decoration: const InputDecoration(
                    labelText: 'Laptop',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Semua Laptop'),
                    ),
                    ...laptopProvider.laptops.map(
                      (laptop) => DropdownMenuItem(
                        value: laptop.laptopId,
                        child: Text(laptop.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLaptopId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Mulai',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Akhir',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedLaptopId = null;
                _startDate = null;
                _endDate = null;
              });
              historyProvider.clearFilters();
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
              historyProvider.setFilter(
                laptopId: _selectedLaptopId,
                startDate: _startDate,
                endDate: _endDate,
              );
              Navigator.of(context).pop();
              _fetchHistory();
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
        title: const Text('Statistik & Riwayat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (historyProvider.error != null) {
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
                    'Error memuat data statistik',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          historyProvider.error!,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (historyProvider.error!
                                .contains('Collection not found') ||
                            historyProvider.error!
                                .contains('maintenance_history'))
                          Text(
                            'Kemungkinan collection "maintenance_history" belum dibuat. Silakan jalankan setup database Appwrite.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchHistory,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchHistory(),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            strokeWidth: 3.0,
            displacement: 60.0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOutCubicEmphasized,
              switchOutCurve: Curves.easeInOutCubicEmphasized,
              child: SingleChildScrollView(
                key: ValueKey(historyProvider.history.length),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Overview with entrance animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubicEmphasized,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildStatisticsOverview(historyProvider),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Recent History with stagger animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutCubicEmphasized,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildRecentHistory(historyProvider),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsOverview(HistoryProvider historyProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Statistik',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Stats Cards Row 1
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.build,
                title: 'Total Perawatan',
                value: historyProvider.totalMaintenanceCount.toString(),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month,
                title: 'Bulan Ini',
                value: historyProvider.thisMonthMaintenanceCount.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stats Cards Row 2
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.date_range,
                title: 'Minggu Ini',
                value: historyProvider.thisWeekMaintenanceCount.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<LaptopProvider>(
                builder: (context, laptopProvider, child) {
                  return _StatCard(
                    icon: Icons.laptop,
                    title: 'Total Laptop',
                    value: laptopProvider.laptops.length.toString(),
                    color: Colors.blue,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stats Cards Row 3
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.build_circle,
                title: 'Laptop Terawat',
                value: historyProvider.maintenanceByLaptop.length.toString(),
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<LaptopProvider>(
                builder: (context, laptopProvider, child) {
                  final totalLaptops = laptopProvider.laptops.length;
                  final maintainedLaptops =
                      historyProvider.maintenanceByLaptop.length;
                  final percentage = totalLaptops > 0
                      ? ((maintainedLaptops / totalLaptops) * 100).round()
                      : 0;

                  return _StatCard(
                    icon: Icons.percent,
                    title: 'Tingkat Perawatan',
                    value: '$percentage%',
                    color: Colors.teal,
                  );
                },
              ),
            ),
          ],
        ),

        // Maintenance by Laptop
        if (historyProvider.maintenanceByLaptop.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Perawatan per Laptop',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<LaptopProvider>(
                builder: (context, laptopProvider, child) {
                  return Column(
                    children: historyProvider.maintenanceByLaptop.entries
                        .map((entry) {
                      final laptop = laptopProvider.laptops.firstWhere(
                        (l) => l.laptopId == entry.key,
                        orElse: () => Laptop(
                          laptopId: entry.key,
                          userId: '',
                          name: 'Laptop Tidak Diketahui',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.laptop,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                laptop.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentHistory(HistoryProvider historyProvider) {
    final recentHistory = historyProvider.getRecentHistory(limit: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Terkini',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (historyProvider.history.length > 10)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full history screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Fitur view all history akan segera tersedia'),
                    ),
                  );
                },
                child: const Text('Lihat Semua'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentHistory.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada riwayat perawatan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Statistik akan muncul setelah Anda menyelesaikan task maintenance',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cara Membuat Data Statistik:',
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
                      const SizedBox(height: 12),
                      _buildInstructionStep('1. Buat task di tab "Tasks"'),
                      _buildInstructionStep(
                          '2. Klik tombol "Complete" pada task'),
                      _buildInstructionStep(
                          '3. Kembali ke Statistik untuk melihat data'),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Refresh halaman ini setelah menyelesaikan task',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        DefaultTabController.of(context)?.animateTo(1);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.task),
                      label: const Text('Lihat Tasks'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _fetchHistory,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final history = recentHistory[index];
              return _HistoryCard(history: history);
            },
          ),
      ],
    );
  }

  Widget _buildInstructionStep(String step) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          step,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MaintenanceHistory history;

  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          'Perawatan Selesai',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Task ID: ${history.taskId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (history.notes != null && history.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                history.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${history.completionDate.day}/${history.completionDate.month}/${history.completionDate.year}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '${history.completionDate.hour.toString().padLeft(2, '0')}:${history.completionDate.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
 