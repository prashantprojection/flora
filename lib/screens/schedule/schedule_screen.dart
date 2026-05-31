import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/services/image_picker_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/widgets/offline_banner.dart';

import 'package:flora/screens/schedule/components/schedule_task_card.dart';
import 'package:flora/screens/schedule/components/schedule_calendar_strip.dart';
import 'package:flora/screens/schedule/components/schedule_empty_state.dart';

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
          const OfflineBanner(),
          ScheduleCalendarStrip(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
            hasTasksForDate: (date) => _hasTasksForDate(plants, date),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasksForSelectedDate.isEmpty
                ? ScheduleEmptyState(
                    isToday: _isSameDay(_selectedDate, DateTime.now()),
                  )
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

  bool _hasTasksForDate(List<Plant> plants, DateTime date) {
    return _getTasksForDate(plants, date).isNotEmpty;
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
        title: const Text('Nice work!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to your growth journal?'),
            SizedBox(height: 8),
            Text(
              'Capture progress to see your plant grow over time.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.camera),
            label: const Text('Add Photo'),
          ),
        ],
      ),
    );

    if (shouldTakePhoto == null) return false; // Dismissed -> Cancel

    String? photoPath;

    if (shouldTakePhoto) {
      final File? image = await ImagePickerService.pickImage(fromCamera: true);
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
