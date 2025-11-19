import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/widgets/add_plant_sheet.dart';
import 'package:flora/widgets/ai_care_tips.dart';
import 'package:flora/widgets/care_history_list.dart';
import 'package:flora/widgets/log_care_sheet.dart'; // Updated import

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantListProvider);
    final Plant plant = plants.firstWhere(
      (p) => p.id == plantId,
      orElse: () => plants.first,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 250,
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return AddPlantSheet(plant: plant);
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Plant'),
                          content: Text(
                            'Are you sure you want to delete ${plant.name}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(plantListProvider.notifier)
                                    .deletePlant(plant.id);
                                Navigator.of(context).pop(); // Close dialog
                                context.go('/'); // Navigate back to home
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    plant.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  background:
                      plant.imageUrl != null &&
                          plant.imageUrl!.startsWith('http')
                      ? Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(LucideIcons.flower2, size: 100),
                        )
                      : (plant.imageUrl != null
                            ? Image.file(
                                File(plant.imageUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(LucideIcons.flower2, size: 100),
                              )
                            : const Icon(LucideIcons.flower2, size: 100)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildPlantDetailsCard(context, plant),
                      const SizedBox(height: 16),
                      AICareTips(plant: plant),
                      const SizedBox(height: 16),
                      CareHistoryList(careHistory: plant.careHistory),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return LogCareSheet(plantId: plant.id);
                },
              );
            },
            child: const Icon(LucideIcons.plus),
          );
        },
      ),
    );
  }

  Widget _buildPlantDetailsCard(BuildContext context, Plant plant) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: plant.imageUrl != null && plant.imageUrl!.startsWith('http')
                ? Image.network(
                    plant.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(LucideIcons.flower2, size: 100),
                  )
                : (plant.imageUrl != null
                      ? Image.file(
                          File(plant.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(LucideIcons.flower2, size: 100),
                        )
                      : const Icon(LucideIcons.flower2, size: 100)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  plant.species ?? "Unknown Species",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  LucideIcons.calendar,
                  'Planted on ${DateFormat.yMMMMd().format(plant.plantingDate)}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  LucideIcons.mapPin,
                  'Located in ${plant.location ?? "Not Specified"}',
                ), // Location is not in the model yet
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  LucideIcons.droplets,
                  'Water every ${plant.nextWatering.difference(plant.lastWatered).inDays} days',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
