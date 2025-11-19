import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/widgets/plant_card.dart';
import 'package:flora/widgets/bottom_nav_bar.dart';
import 'package:flora/widgets/add_plant_sheet.dart';
import 'package:flora/utils/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Map<String, dynamic> _getWateringStatus(Plant plant) {
    final daysUntilNextWatering = plant.nextWatering
        .difference(DateTime.now())
        .inDays;

    return {
      'needsWater': daysUntilNextWatering <= 0,
      'overdue': daysUntilNextWatering <= 0 ? daysUntilNextWatering.abs() : 0,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantListProvider);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    final plantsNeedingWater =
        plants.where((p) => _getWateringStatus(p)['needsWater']).toList()..sort(
          (a, b) =>
              _getWateringStatus(b)['overdue'] -
              _getWateringStatus(a)['overdue'],
        );

    final otherPlants = plants
        .where((p) => !_getWateringStatus(p)['needsWater'])
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sprout,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(width: AppTheme.spacing_2),
            Text(
              'My Garden',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      body: plants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.sprout,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: AppTheme.spacing_4),
                  Text(
                    'Your garden is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing_2),
                  Text(
                    'Add your first plant to get started.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing_4),
                  ElevatedButton.icon(
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
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing_4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plantsNeedingWater.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppTheme.spacing_2,
                            bottom: AppTheme.spacing_2,
                          ),
                          child: Text(
                            'Watering Reminders',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plantsNeedingWater.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacing_4,
                              ),
                              child: PlantCard(
                                plant: plantsNeedingWater[index],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing_8),
                      ],
                    ),
                  if (otherPlants.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppTheme.spacing_2,
                            bottom: AppTheme.spacing_2,
                          ),
                          child: Text(
                            plantsNeedingWater.isNotEmpty
                                ? 'Other Plants'
                                : 'All Plants',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: otherPlants.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacing_4,
                              ),
                              child: PlantCard(plant: otherPlants[index]),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
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
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
