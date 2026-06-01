import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/services/platform_share_service.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/screens/plant_detail/components/ai_care_tips.dart';
import 'package:flora/screens/plant_detail/components/growth_timeline.dart';
import 'package:flora/screens/plant_detail/components/care_history_list.dart';
import 'package:flora/screens/plant_detail/components/log_care_sheet.dart';
import 'package:flora/widgets/add_plant_sheet/add_plant_sheet.dart';
import 'package:flora/models/care_event.dart';

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

    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black26,
                child: Icon(LucideIcons.arrowLeft, color: Colors.white),
              ),
              onPressed: () => context.go('/'),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(
                    LucideIcons.share2,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  final String speciesStr = plant.species != null && plant.species!.isNotEmpty ? ' (${plant.species})' : '';
                  final String locationStr = plant.location != null && plant.location!.isNotEmpty ? '\nLocation: ${plant.location}' : '';
                  final String frequencyStr = plant.wateringFrequency != null ? '\nWatering Schedule: Every ${plant.wateringFrequency} days' : '';
                  final String instructionsStr = plant.careInstructions != null && plant.careInstructions!.isNotEmpty ? '\n\nCare Instructions:\n${plant.careInstructions}' : '';
                  
                  final summary = 'Plant Summary: ${plant.name}$speciesStr$locationStr$frequencyStr$instructionsStr';
                  
                  PlatformShareService.shareText(
                    summary,
                    subject: 'Care Info: ${plant.name}',
                  );
                },
              ),
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(
                    LucideIcons.pencil,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddPlantSheet(plant: plant),
                  );
                },
              ),
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(
                    LucideIcons.trash2,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => _confirmDelete(context, ref, plant),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPlantImage(plant),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          plant.name,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plant.species != null && plant.species!.isNotEmpty)
                          Text(
                            plant.species!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(context, plant),
                  const SizedBox(height: 32),
                  Text(
                    'Smart Care',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AICareTips(plant: plant),
                  const SizedBox(height: 32),
                  GrowthTimeline(plant: plant),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Care History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showFullHistory(context, plant),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CareHistoryList(careHistory: plant.careHistory, limit: 5),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => LogCareSheet(plantId: plant.id),
          );
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Log Care'),
      ),
    );
  }

  Widget _buildPlantImage(Plant plant) {
    if (plant.imageUrl == null) {
      return Container(
        color: Colors.green.shade100,
        child: const Icon(LucideIcons.flower2, size: 80, color: Colors.green),
      );
    }
    if (plant.imageUrl!.startsWith('http')) {
      return Image.network(
        plant.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Icon(LucideIcons.imageOff),
        ),
      );
    }
    return Image.file(
      File(plant.imageUrl!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(LucideIcons.imageOff),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, Plant plant) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: LucideIcons.calendar,
                label: 'Age',
                value: _getAge(plant.plantingDate),
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: LucideIcons.mapPin,
                label: 'Location',
                value: plant.location?.isNotEmpty == true ? plant.location! : 'N/A',
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: LucideIcons.droplets,
                label: 'Water',
                value: _formatNextDate(plant.nextWatering),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: LucideIcons.flaskConical,
                label: 'Fertilize',
                value: _getScheduleNextDate(plant, CareType.fertilizing) != null ? _formatNextDate(_getScheduleNextDate(plant, CareType.fertilizing)!) : 'N/A',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: LucideIcons.scissors,
                label: 'Prune',
                value: _getScheduleNextDate(plant, CareType.pruning) != null ? _formatNextDate(_getScheduleNextDate(plant, CareType.pruning)!) : 'N/A',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  DateTime? _getScheduleNextDate(Plant plant, CareType type) {
    final idx = plant.careSchedules.indexWhere((s) => s.type == type);
    return idx != -1 ? plant.careSchedules[idx].nextDate : null;
  }

  String _formatNextDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  String _getAge(DateTime plantingDate) {
    final diff = DateTime.now().difference(plantingDate).inDays;
    if (diff == 0) return 'Planted today';
    if (diff < 30) return '$diff days';
    if (diff < 365) return '${(diff / 30).floor()} months';
    return '${(diff / 365).floor()} years';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant'),
        content: Text('Are you sure you want to delete ${plant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref.read(plantListProvider.notifier).deletePlant(plant.id);
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFullHistory(BuildContext context, Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Full Care History'),
              leading: IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [CareHistoryList(careHistory: plant.careHistory)],
            ),
          );
        },
      ),
    );
  }
}
