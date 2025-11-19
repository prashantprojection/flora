import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/widgets/bottom_nav_bar.dart';
import 'package:flutter/gestures.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plants = ref.watch(plantListProvider);
    final tasks = _getUpcomingCareTasks(plants);

    final groupedTasks = _groupTasks(tasks);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Care Schedule',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.calendar, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'All Caught Up!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'There are no upcoming care tasks for your garden.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: groupedTasks.entries.map((entry) {
                if (entry.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...entry.value.map(
                        (task) => TaskItem(
                          task: task,
                          onComplete: () {
                            final plant = ref
                                .read(plantListProvider)
                                .firstWhere((p) => p.id == task.plantId);
                            final today = DateTime.now();
                            final hasBeenWateredToday = plant.careHistory.any(
                              (event) =>
                                  event.type == CareType.watering &&
                                  event.date.year == today.year &&
                                  event.date.month == today.month &&
                                  event.date.day == today.day,
                            );

                            if (!hasBeenWateredToday) {
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
                                  content: Text(
                                    'Logged ${task.type.toString().split('.').last} for ${task.plantName}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  List<UpcomingCareTask> _getUpcomingCareTasks(List<Plant> plants) {
    final tasks = <UpcomingCareTask>[];
    for (final plant in plants) {
      tasks.add(
        UpcomingCareTask(
          plantId: plant.id,
          plantName: plant.name,
          type: CareType.watering,
          dueDate: plant.nextWatering,
        ),
      );
    }
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  Map<String, List<UpcomingCareTask>> _groupTasks(
    List<UpcomingCareTask> tasks,
  ) {
    final groups = <String, List<UpcomingCareTask>>{
      'Today': [],
      'Tomorrow': [],
      'Next 7 Days': [],
      'Upcoming': [],
    };

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final next7Days = today.add(const Duration(days: 7));

    for (final task in tasks) {
      if (task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day) {
        groups['Today']!.add(task);
      } else if (task.dueDate.year == tomorrow.year &&
          task.dueDate.month == tomorrow.month &&
          task.dueDate.day == tomorrow.day) {
        groups['Tomorrow']!.add(task);
      } else if (task.dueDate.isBefore(next7Days)) {
        groups['Next 7 Days']!.add(task);
      } else {
        groups['Upcoming']!.add(task);
      }
    }
    return groups;
  }
}

class UpcomingCareTask {
  final String plantId;
  final String plantName;
  final CareType type;
  final DateTime dueDate;

  UpcomingCareTask({
    required this.plantId,
    required this.plantName,
    required this.type,
    required this.dueDate,
  });
}

class TaskItem extends StatelessWidget {
  final UpcomingCareTask task;
  final VoidCallback onComplete;

  const TaskItem({super.key, required this.task, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final details = _getCareTypeDetails(task.type, context);
    final now = DateTime.now();
    final isToday =
        task.dueDate.year == now.year &&
        task.dueDate.month == now.month &&
        task.dueDate.day == now.day;

    return ListTile(
      leading: Icon(details['icon'], color: details['color']),
      title: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium,
          children: [
            TextSpan(text: '${details['label']} '),
            TextSpan(
              text: task.plantName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.go('/plant/${task.plantId}'),
            ),
          ],
        ),
      ),
      subtitle: Text(
        DateFormat.yMMMd().format(task.dueDate),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: TextButton(
        onPressed: isToday ? onComplete : null,
        child: const Text('Mark Done'),
      ),
    );
  }

  Map<String, dynamic> _getCareTypeDetails(
    CareType type,
    BuildContext context,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case CareType.watering:
        return {
          'icon': LucideIcons.droplets,
          'label': 'Water',
          'color': colorScheme.primary,
        };
      case CareType.fertilizing:
        return {
          'icon': LucideIcons.leaf,
          'label': 'Fertilize',
          'color': colorScheme.secondary,
        };
      case CareType.pruning:
        return {
          'icon': LucideIcons.scissors,
          'label': 'Prune',
          'color': colorScheme.onSurface,
        };
    }
  }
}
