import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';

import 'package:flora/widgets/add_plant_sheet/add_plant_sheet.dart';

import 'package:flora/api/notification_service.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/services/preferences_service.dart';
import 'package:flora/screens/home/components/onboarding_card.dart';
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
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    // Request permissions and schedule reminders after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.requestPermissions();
      notificationService.scheduleDailyReminder();
    });
  }

  Future<void> _checkOnboarding() async {
    final onboardingShown = PreferencesService.hasSeenOnboarding;
    if (!onboardingShown) {
      setState(() {
        _showOnboarding = true;
      });
    }
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

    final mainContent = Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
          const HomeHeader(),
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
            const HomeEmptyState()
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
            HomeUrgentCareSection(
              plantsNeedingCare: plantsNeedingCare,
              onWaterAll: () => _showBulkWaterDialog(plantsNeedingCare),
            ),
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
            HomePlantGrid(plants: otherPlants),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ],
      ),
          ),
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

    if (_showOnboarding) {
      return Stack(
        children: [
          mainContent,
          OnboardingCard(
            onDismiss: () => setState(() => _showOnboarding = false),
          ),
        ],
      );
    }
    return mainContent;
  }
}
