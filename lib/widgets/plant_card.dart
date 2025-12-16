import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/utils/app_theme.dart';

class PlantCard extends StatelessWidget {
  final Plant plant;

  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final wateringStatus = _getWateringStatus(plant);

    return GestureDetector(
      onTap: () => context.push('/plant/${plant.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppTheme.borderRadiusLg,
          ), // More rounded corners
        ),
        elevation: 2, // Add a subtle shadow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant Image
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child:
                    plant.imageUrl != null && plant.imageUrl!.startsWith('http')
                    ? Image.network(
                        plant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            LucideIcons.flower2,
                            size: 60,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                      )
                    : (plant.imageUrl != null
                          ? Image.file(
                              File(plant.imageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      LucideIcons.flower2,
                                      size: 60,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(128),
                                    ),
                                  ),
                            )
                          : Center(
                              child: Icon(
                                LucideIcons.flower2,
                                size: 60,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(128),
                              ),
                            )),
              ),
            ),
            // Plant Details
            Padding(
              padding: const EdgeInsets.all(
                AppTheme.spacing_3,
              ), // Increased padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ), // More prominent name
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing_1), // Smaller spacing
                  Text(
                    plant.species ?? "Unknown Species",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: AppTheme.spacing_2,
                  ), // Spacing before watering status
                  // Watering Status
                  Row(
                    children: [
                      Icon(
                        wateringStatus['icon'],
                        size: 18,
                        color: wateringStatus['color'],
                      ),
                      const SizedBox(width: AppTheme.spacing_1),
                      Expanded(
                        child: Text(
                          wateringStatus['text'],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: wateringStatus['color'],
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // "Water me!" indicator (if applicable)
            if (wateringStatus['needsWater'])
              Container(
                width: double.infinity, // Full width
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing_3,
                  vertical: AppTheme.spacing_2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.borderRadiusLg),
                  ), // Match card border radius
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.droplets,
                      color: Theme.of(context).colorScheme.onError,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacing_1),
                    Text(
                      'Water me!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getWateringStatus(Plant plant) {
    final daysUntilNextWatering = plant.nextWatering
        .difference(DateTime.now())
        .inDays;

    if (daysUntilNextWatering <= 0) {
      return {
        'text': 'Water now! Overdue by ${daysUntilNextWatering.abs()} days',
        'needsWater': true,
        'days': daysUntilNextWatering.abs(),
        'color': Colors.red,
        'icon': LucideIcons.droplets,
      };
    } else if (daysUntilNextWatering <= 2) {
      return {
        'text': 'Water in $daysUntilNextWatering days',
        'needsWater': false,
        'days': daysUntilNextWatering,
        'color': Colors.orange,
        'icon': LucideIcons.droplets,
      };
    }
    return {
      'text': 'Water in $daysUntilNextWatering days',
      'needsWater': false,
      'days': daysUntilNextWatering,
      'color': Colors.green,
      'icon': LucideIcons.droplets,
    };
  }
}
