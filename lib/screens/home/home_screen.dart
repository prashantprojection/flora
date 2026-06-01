import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';

import 'package:flora/widgets/add_plant_sheet/add_plant_sheet.dart';

import 'package:flora/api/notification_service.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/screens/home/components/bulk_water_dialog.dart';
import 'package:flora/screens/home/components/home_empty_state.dart';
import 'package:flora/screens/home/components/home_plant_grid.dart';
import 'package:flora/screens/home/components/home_header.dart';
import 'package:flora/screens/home/components/home_urgent_care_section.dart';
import 'package:flora/widgets/offline_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  // Simple filters for now
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Request permissions and schedule reminders after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.requestPermissions();
      notificationService.scheduleDailyReminder();
    });
  }

  // Uses inDays (floor division) — consistent with PlantCard and avoids rounding bugs
  // where a plant watered moments ago still shows "needs care" due to .round().
  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static Map<String, dynamic> getCareStatus(Plant plant) {
    final today = _startOfDay(DateTime.now());
    final nextWatering = _startOfDay(plant.nextWatering);
    int minDays = nextWatering.difference(today).inDays;

    // Check other schedules
    for (final schedule in plant.careSchedules) {
      final diff = _startOfDay(schedule.nextDate).difference(today).inDays;
      if (diff < minDays) minDays = diff;
    }

    return {
      'needsCare': minDays <= 0,
      'overdue': minDays < 0 ? minDays.abs() : 0,
      'daysUntil': minDays,
    };
  }

  void _showBulkWaterDialog(BuildContext scaffoldContext, List<Plant> needyPlants) {
    showDialog(
      context: context,
      builder: (context) {
        return BulkWaterDialog(
          plants: needyPlants,
          onConfirm: (selectedIds) {
            for (final id in selectedIds) {
              ref
                  .read(plantListProvider.notifier)
                  .addCareEvent(
                    id,
                    CareEvent(
                      id: DateTime.now().toIso8601String(),
                      date: DateTime.now(),
                      type: CareType.watering,
                    ),
                  );
            }
            // Use the outer scaffold context — safe even after dialog is popped
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(content: Text('Watered ${selectedIds.length} plants!')),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter Plants',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedFilter != 'All')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'All';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final locations = ref.watch(locationListProvider);
                  final filters = ['All', 'Archive', ...locations];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final allPlants = ref.watch(plantListProvider);
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    // Pre-compute statuses ONCE per build to avoid O(n²) re-computation.
    final careStatuses = {
      for (final p in allPlants) p.id: getCareStatus(p),
    };

    final plants = allPlants.where((p) {
      if (_selectedFilter == 'Archive') {
        return p.status == PlantStatus.givenAway || p.status == PlantStatus.deceased;
      }
      final bool isActive = p.status == PlantStatus.active || p.status == PlantStatus.quarantine || p.status == null;
      if (!isActive) return false;

      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.species?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesFilter =
          _selectedFilter == 'All' || p.location == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    final plantsNeedingCare = _selectedFilter == 'Archive'
        ? <Plant>[]
        : plants.where((p) => careStatuses[p.id]!['needsCare'] as bool).toList()
          ..sort(
            (a, b) =>
                (careStatuses[b.id]!['overdue'] as int) -
                (careStatuses[a.id]!['overdue'] as int),
          );

    final otherPlants =
        plants.where((p) => !(careStatuses[p.id]!['needsCare'] as bool)).toList();

    return Scaffold(
      body: Builder(
        // Builder gives us a context that has the Scaffold's ScaffoldMessenger,
        // safe to use in dialog callbacks after the dialog is closed.
        builder: (scaffoldContext) {
          return Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    HomeHeader(greeting: _getGreeting()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search your garden...',
                            prefixIcon: const Icon(LucideIcons.search),
                            suffixIcon: IconButton(
                              icon: Icon(
                                LucideIcons.slidersHorizontal,
                                color: _selectedFilter == 'All'
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.primary,
                              ),
                              onPressed: _showFilterDialog,
                              tooltip: 'Filter Plants',
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    if (plants.isEmpty)
                      const HomeEmptyState()
                    else ...[
                      HomeUrgentCareSection(
                        plantsNeedingCare: plantsNeedingCare,
                        onWaterAll: () =>
                            _showBulkWaterDialog(scaffoldContext, plantsNeedingCare),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.flower2,
                                size: 18,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedFilter == 'Archive'
                                    ? 'Archived Plants'
                                    : plantsNeedingCare.isNotEmpty
                                        ? 'Thriving Plants'
                                        : 'Your Collection',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${otherPlants.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      HomePlantGrid(plants: otherPlants),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isLargeScreen
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return const AddPlantSheet();
                  },
                );
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Plant'),
            ),
    );
  }
}
