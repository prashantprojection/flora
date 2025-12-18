import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/screens/plant_detail_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plants = ref.watch(plantListProvider);
    final tasksForSelectedDate = _getTasksForDate(plants, _selectedDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMd().format(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Care Schedule',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Jump to today
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            icon: const Icon(LucideIcons.calendar),
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCalendarStrip(theme, plants),
          const SizedBox(height: 16),
          Expanded(
            child: tasksForSelectedDate.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: tasksForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final selected = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );
                      // Actionable if selected date is today or in the past
                      final isActionable = !selected.isAfter(today);
                      final task = tasksForSelectedDate[index];

                      return Dismissible(
                        key: ValueKey(
                          '${task.plantId}_${task.type}_${task.dueDate}',
                        ),
                        direction: isActionable
                            ? DismissDirection.horizontal
                            : DismissDirection.none,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.check, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Mark Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Snooze',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(LucideIcons.clock, color: Colors.white),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Mark Done
                            final completed = await _handleTaskCompletion(task);
                            return completed;
                          } else {
                            // Snooze
                            ref
                                .read(plantListProvider.notifier)
                                .snoozePlant(task.plantId, type: task.type);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Snoozed for 1 day'),
                              ),
                            );
                            return true; // Remove from list
                          }
                        },
                        child: ScheduleTaskCard(
                          task: task,
                          onComplete: isActionable
                              ? () => _handleTaskCompletion(task)
                              : null,
                          onSnooze: isActionable
                              ? () {
                                  ref
                                      .read(plantListProvider.notifier)
                                      .snoozePlant(
                                        task.plantId,
                                        type: task.type,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Snoozed for 1 day'),
                                    ),
                                  );
                                }
                              : null,
                          onSkip: isActionable
                              ? () {
                                  ref
                                      .read(plantListProvider.notifier)
                                      .skipPlant(task.plantId, type: task.type);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Skipped this cycle'),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(ThemeData theme, List<Plant> plants) {
    final today = DateTime.now();
    // Generate dates for the next 2 weeks
    final dates = List.generate(
      14,
      (index) => today.add(Duration(days: index)),
    );

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, today);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (_hasTasksForDate(plants, date))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.onPrimary.withOpacity(0.5)
                            : theme.colorScheme.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasTasksForDate(List<Plant> plants, DateTime date) {
    return _getTasksForDate(plants, date).isNotEmpty;
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.calendarCheck2,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tasks for ${_isSameDay(_selectedDate, DateTime.now()) ? "Today" : "This Day"}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your plants are happy and healthy!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UpcomingCareTask> _getTasksForDate(List<Plant> plants, DateTime date) {
    final tasks = <UpcomingCareTask>[];
    final normalizedSelected = DateTime(date.year, date.month, date.day);

    for (final plant in plants) {
      // 1. Check Watering (Default)
      _checkAndAddTask(
        tasks,
        plant,
        CareType.watering,
        plant.nextWatering,
        plant.lastWatered,
        plant.wateringFrequency ?? 7,
        normalizedSelected,
        date,
      );

      // 2. Check Additional Schedules
      for (final schedule in plant.careSchedules) {
        _checkAndAddTask(
          tasks,
          plant,
          schedule.type,
          schedule.nextDate,
          schedule.lastDate,
          schedule.frequency,
          normalizedSelected,
          date,
        );
      }
    }
    return tasks;
  }

  void _checkAndAddTask(
    List<UpcomingCareTask> tasks,
    Plant plant,
    CareType type,
    DateTime nextDate,
    DateTime lastDate,
    int frequency,
    DateTime normalizedSelected,
    DateTime originalSelectedDate,
  ) {
    // Normalize dates
    final normalizedNext = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
    );

    // Check if the selected date is the next due date OR a future recurrence
    // We only show tasks that are due ON or BEFORE the selected date (visual history)
    // For future dates (daysFromNext < 0), we hide them (Snoozed tasks fall here for the original date).
    final daysFromNext = normalizedSelected.difference(normalizedNext).inDays;

    if (daysFromNext >= 0 && daysFromNext % frequency == 0) {
      // Check if Completed OR Skipped on this date
      final isCompleted = plant.careHistory.any(
        (event) =>
            (event.type == type || event.type == CareType.skipped) &&
            _isSameDay(event.date, normalizedSelected),
      );

      tasks.add(
        UpcomingCareTask(
          plantId: plant.id,
          plantName: plant.name,
          plantImage: plant.imageUrl,
          type: type,
          dueDate: originalSelectedDate, // Use the visual date
          isCompleted: isCompleted,
        ),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> _handleTaskCompletion(UpcomingCareTask task) async {
    final plant = ref
        .read(plantListProvider)
        .firstWhere((p) => p.id == task.plantId);
    final today = DateTime.now();

    // Prevent double logging
    final hasBeenLoggedToday = plant.careHistory.any(
      (event) => event.type == task.type && _isSameDay(event.date, today),
    );

    if (hasBeenLoggedToday) return true;

    // Show dialog to ask for photo
    final shouldTakePhoto = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Great job!'),
        content: const Text(
          'Would you like to add a photo to your growth journal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, just log it'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.camera),
            label: const Text('Take Photo'),
          ),
        ],
      ),
    );

    if (shouldTakePhoto == null) return false; // Dismissed -> Cancel

    String? photoPath;

    if (shouldTakePhoto) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        photoPath = image.path;
      }
    }

    if (!mounted) return false;

    ref
        .read(plantListProvider.notifier)
        .addCareEvent(
          task.plantId,
          CareEvent(
            id: DateTime.now().toString(),
            type: task.type,
            date: DateTime.now(),
            photoUrl: photoPath,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked ${task.plantName} as ${task.type.name}${photoPath != null ? " with a photo!" : ""}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return true;
  }
}

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
                            color: isActionable
                                ? details['color']
                                : Colors.grey,
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
            const SizedBox(width: 8), // Reduced spacing
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
                  minimumSize: const Size(0, 36), // Compact height
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap, // Compact touch
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  task.isCompleted
                      ? 'Done'
                      : (isActionable ? 'Done' : 'Scheduled'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (!task.isCompleted && isActionable) ...[
              const SizedBox(width: 0), // Tight spacing
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
        return {
          'icon': LucideIcons.skipForward,
          'label': 'Skipped',
          'color': Colors.grey,
        };
    }
  }
}
