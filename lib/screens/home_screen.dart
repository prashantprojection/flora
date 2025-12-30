import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/widgets/plant_card.dart';
import 'package:flora/widgets/add_plant_sheet.dart';

import 'package:flora/api/notification_service.dart';
import 'package:flora/widgets/bulk_water_dialog.dart';
import 'package:flora/models/care_event.dart';

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

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> _getCareStatus(Plant plant) {
    final now = DateTime.now();
    final today = _startOfDay(now);

    // Check Watering
    final nextWatering = _startOfDay(plant.nextWatering);
    int minDaysUsingWatering = (nextWatering.difference(today).inHours / 24)
        .round();

    // Check other schedules
    for (final schedule in plant.careSchedules) {
      final nextSchedule = _startOfDay(schedule.nextDate);
      final diff = (nextSchedule.difference(today).inHours / 24).round();
      if (diff < minDaysUsingWatering) {
        minDaysUsingWatering = diff;
      }
    }

    return {
      // Needs care if any task is due today (0) or overdue (< 0)
      'needsCare': minDaysUsingWatering <= 0,
      'overdue': minDaysUsingWatering < 0 ? minDaysUsingWatering.abs() : 0,
      'daysUntil': minDaysUsingWatering,
    };
  }

  void _showBulkWaterDialog(List<Plant> needyPlants) {
    showDialog(
      context: context,
      builder: (context) {
        return BulkWaterDialog(
          plants: needyPlants,
          onConfirm: (selectedIds) {
            for (final id in selectedIds) {
              // Add Water event for today
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
            ScaffoldMessenger.of(context).showSnackBar(
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
                  final filters = ['All', ...locations];
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
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final allPlants = ref.watch(plantListProvider); // Rename local var
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    // 1. Filter Logic
    final plants = allPlants.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.species?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesFilter =
          _selectedFilter == 'All' || p.location == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    final plantsNeedingCare =
        plants.where((p) => _getCareStatus(p)['needsCare']).toList()..sort(
          (a, b) => _getCareStatus(b)['overdue'] - _getCareStatus(a)['overdue'],
        );

    final otherPlants = plants
        .where((p) => !_getCareStatus(p)['needsCare'])
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            pinned: true,
            expandedHeight: 180,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: Text(
                'My Garden',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 40,
                      right: -20,
                      child: Icon(
                        LucideIcons.sprout,
                        size: 150,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar with Filter
                  TextField(
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
                ],
              ),
            ),
          ),
          if (plants.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.sprout,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your garden is empty',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first plant to get started.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => const AddPlantSheet(),
                            );
                          },
                          label: const Text('Add Plant'),
                          icon: const Icon(LucideIcons.plus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Text(
                  _getGreeting(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (plantsNeedingCare.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.droplets,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Attention Needed',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${plantsNeedingCare.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (plantsNeedingCare.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showBulkWaterDialog(plantsNeedingCare),
                          icon: const Icon(LucideIcons.droplets, size: 14),
                          label: const Text('Water All'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280, // Height for horizontal scrolling cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: plantsNeedingCare.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 300,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: PlantCard(plant: plantsNeedingCare[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.flower2,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plantsNeedingCare.isNotEmpty
                          ? 'Thriving Plants'
                          : 'Your Collection',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.1,
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 900
                      ? 4
                      : MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
                  childAspectRatio: 0.7, // Taller cards
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return PlantCard(plant: otherPlants[index]);
                }, childCount: otherPlants.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ],
      ),
      floatingActionButton: isLargeScreen
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return const AddPlantSheet();
                  },
                );
              },
              child: const Icon(LucideIcons.plus),
            ),
    );
  }
}
