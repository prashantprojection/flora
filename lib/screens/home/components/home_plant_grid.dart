import 'package:flutter/material.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/widgets/plant_card.dart';

class HomePlantGrid extends StatelessWidget {
  final List<Plant> plants;

  const HomePlantGrid({super.key, required this.plants});

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
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
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return PlantCard(plant: plants[index]);
          },
          childCount: plants.length,
        ),
      ),
    );
  }
}
