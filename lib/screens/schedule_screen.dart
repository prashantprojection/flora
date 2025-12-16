import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';

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

                      return ScheduleTaskCard(
                        task: tasksForSelectedDate[index],
                        onComplete: isActionable
                            ? () => _handleTaskCompletion(
                                tasksForSelectedDate[index],
                              )
                            : null,
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
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
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
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.5)
                            : theme.colorScheme.primary.withValues(alpha: 0.5),
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.calendarCheck2,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
      // Normalize plant dates to ignore time components
      final normalizedNext = DateTime(
        plant.nextWatering.year,
        plant.nextWatering.month,
        plant.nextWatering.day,
      );
      final normalizedLast = DateTime(
        plant.lastWatered.year,
        plant.lastWatered.month,
        plant.lastWatered.day,
      );

      // Infer frequency
      final frequency = normalizedNext.difference(normalizedLast).inDays;

      if (frequency <= 0) {
        continue;
      } // Avoid division by zero or negative frequency

      // Calculate difference from the *next* scheduled watering
      final daysFromNext = normalizedSelected.difference(normalizedNext).inDays;

      // Check if the selected date is the next watering date OR a future recurrence
      if (daysFromNext >= 0 && daysFromNext % frequency == 0) {
        tasks.add(
          UpcomingCareTask(
            plantId: plant.id,
            plantName: plant.name,
            plantImage: plant.imageUrl,
            type: CareType.watering,
            dueDate:
                date, // The due date for *this* recurrence is the selected date
          ),
        );
      }
    }
    return tasks;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleTaskCompletion(UpcomingCareTask task) {
    final plant = ref
        .read(plantListProvider)
        .firstWhere((p) => p.id == task.plantId);
    final today = DateTime.now();

    // Check if *currently* visible task is for strictly today, allow completing it.
    // Or if it's a past due task.
    // For future tasks, maybe we want to allow "early" completion?
    // For now, let's just log it as done *now*.

    // Simple check to prevent double logging for the exact same day if button is spammed
    final hasBeenLoggedToday = plant.careHistory.any(
      (event) => event.type == task.type && _isSameDay(event.date, today),
    );

    if (!hasBeenLoggedToday) {
      ref
          .read(plantListProvider.notifier)
          .addCareEvent(
            task.plantId,
            CareEvent(
              id: DateTime.now().toString(),
              type: task.type,
              date: DateTime.now(),
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked ${task.plantName} as watered'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class UpcomingCareTask {
  final String plantId;
  final String plantName;
  final String? plantImage;
  final CareType type;
  final DateTime dueDate;

  UpcomingCareTask({
    required this.plantId,
    required this.plantName,
    this.plantImage,
    required this.type,
    required this.dueDate,
  });
}

class ScheduleTaskCard extends StatelessWidget {
  final UpcomingCareTask task;
  final VoidCallback? onComplete;

  const ScheduleTaskCard({
    super.key,
    required this.task,
    required this.onComplete,
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
                    child: Text(
                      task.plantName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      Text(
                        details['label'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isActionable ? details['color'] : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Action Button
            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: details['color'].withValues(alpha: 0.1),
                foregroundColor: details['color'],
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey,
                elevation: 0,
                minimumSize: const Size(
                  0,
                  40,
                ), // Override global infinite width
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(isActionable ? 'Done' : 'Scheduled'),
            ),
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
    }
  }
}
