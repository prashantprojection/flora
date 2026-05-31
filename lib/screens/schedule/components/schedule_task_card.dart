import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/screens/plant_detail/plant_detail_screen.dart';

class UpcomingCareTask {
  final String plantId;
  final String plantName;
  final String? plantImage;
  final CareType type;
  final DateTime dueDate;
  final bool isCompleted;

  UpcomingCareTask({
    required this.plantId,
    required this.plantName,
    this.plantImage,
    required this.type,
    required this.dueDate,
    this.isCompleted = false,
  });
}

class ScheduleTaskCard extends StatelessWidget {
  final UpcomingCareTask task;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;

  const ScheduleTaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.onSnooze,
    this.onSkip,
  });

  Map<String, dynamic> _getCareTypeDetails(CareType type, BuildContext context) {
    switch (type) {
      case CareType.watering:
        return {
          'icon': LucideIcons.droplets,
          'label': 'Water',
          'color': Colors.blue,
        };
      case CareType.fertilizing:
        return {
          'icon': LucideIcons.leaf,
          'label': 'Fertilize',
          'color': Colors.green,
        };
      case CareType.pruning:
        return {
          'icon': LucideIcons.scissors,
          'label': 'Prune',
          'color': Colors.orange,
        };
      case CareType.skipped:
        return {
          'icon': LucideIcons.skipForward,
          'label': 'Skipped',
          'color': Colors.grey,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _getCareTypeDetails(task.type, context);
    final isActionable = onComplete != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Plant Image or Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                image: task.plantImage != null
                    ? DecorationImage(
                        image: task.plantImage!.startsWith('http')
                            ? NetworkImage(task.plantImage!)
                            : FileImage(File(task.plantImage!))
                                as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: task.plantImage == null
                  ? Icon(LucideIcons.flower2, color: theme.colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            // Task Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        // Navigation to Plant Detail
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                PlantDetailScreen(plantId: task.plantId),
                          ),
                        );
                      },
                      child: Text(
                        task.plantName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        details['icon'],
                        size: 14,
                        color: isActionable ? details['color'] : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          details['label'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isActionable ? details['color'] : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action Button
            if (isActionable)
              ElevatedButton(
                onPressed: task.isCompleted
                    ? null
                    : (isActionable ? onComplete : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: details['color'].withValues(alpha: 0.1),
                  foregroundColor: details['color'],
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  task.isCompleted ? 'Done' : (isActionable ? 'Done' : 'Scheduled'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (!task.isCompleted && isActionable) ...[
              const SizedBox(width: 0),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                onSelected: (value) {
                  if (value == 'snooze') {
                    onSnooze?.call();
                  } else if (value == 'skip') {
                    onSkip?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'snooze',
                    child: Row(
                      children: [
                        Icon(LucideIcons.clock, size: 16),
                        SizedBox(width: 8),
                        Text('Snooze (1 day)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'skip',
                    child: Row(
                      children: [
                        Icon(LucideIcons.skipForward, size: 16),
                        SizedBox(width: 8),
                        Text('Skip this cycle'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
