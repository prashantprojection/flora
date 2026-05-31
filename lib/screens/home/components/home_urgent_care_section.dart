import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/widgets/plant_card.dart';

class HomeUrgentCareSection extends StatelessWidget {
  final List<Plant> plantsNeedingCare;
  final VoidCallback onWaterAll;

  const HomeUrgentCareSection({
    super.key,
    required this.plantsNeedingCare,
    required this.onWaterAll,
  });

  @override
  Widget build(BuildContext context) {
    if (plantsNeedingCare.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
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
                OutlinedButton.icon(
                  onPressed: onWaterAll,
                  icon: const Icon(LucideIcons.droplets, size: 14),
                  label: const Text('Water All'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
