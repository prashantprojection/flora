import 'package:flora/utils/image_utils.dart';
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

  Map<String, dynamic> _getCareTypeDetails(
    CareType type,
    BuildContext context,
  ) {
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
      case CareType.snoozed:
        return {
          'icon': LucideIcons.skipForward,
          'label': type == CareType.snoozed ? 'Snoozed' : 'Skipped',
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: details['color'].withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Plant Image or Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: details['color'].withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  image: task.plantImage != null
                      ? DecorationImage(
                          image: task.plantImage!.startsWith('http')
                              ? NetworkImage(task.plantImage!)
                              : getImageProvider(task.plantImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: task.plantImage == null
                    ? Icon(
                        LucideIcons.flower2,
                        color: details['color'],
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Task Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isActionable
                                  ? details['color']
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () {
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.type == CareType.watering &&
                        !task.isCompleted) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            size: 10,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Check soil 2cm deep before watering',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((task.type == CareType.fertilizing ||
                            task.type == CareType.pruning) &&
                        !task.isCompleted) ...[
                      Builder(
                        builder: (context) {
                          final month = DateTime.now().month;
                          // Standard NH winter check (Dec, Jan, Feb)
                          final isWinter =
                              month == 12 || month == 1 || month == 2;
                          if (isWinter) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.snowflake,
                                    size: 10,
                                    color: Colors.blue.shade300,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Winter dormancy: consider skipping',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.blue.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Action Button
              if (isActionable)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: task.isCompleted
                        ? []
                        : [
                            BoxShadow(
                              color: details['color'].withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: task.isCompleted ? null : onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.isCompleted
                          ? theme.colorScheme.surfaceContainerHighest
                          : details['color'],
                      foregroundColor: task.isCompleted
                          ? Colors.grey
                          : Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.isCompleted)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(LucideIcons.check, size: 14),
                          ),
                        Text(
                          task.isCompleted ? 'Done' : 'Do It',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!task.isCompleted && isActionable) ...[
                const SizedBox(width: 4),
                Theme(
                  data: theme.copyWith(
                    iconTheme: IconThemeData(color: details['color']),
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            Icon(LucideIcons.clock, size: 18),
                            SizedBox(width: 12),
                            Text(
                              'Snooze (1 day)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'skip',
                        child: Row(
                          children: [
                            Icon(LucideIcons.skipForward, size: 18),
                            SizedBox(width: 12),
                            Text(
                              'Skip this cycle',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
