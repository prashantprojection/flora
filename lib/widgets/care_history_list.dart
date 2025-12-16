import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/utils/app_theme.dart';

class CareHistoryList extends StatelessWidget {
  final List<CareEvent> careHistory;
  final int? limit;

  const CareHistoryList({super.key, required this.careHistory, this.limit});

  @override
  Widget build(BuildContext context) {
    final sortedHistory = List<CareEvent>.from(careHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    final displayList = limit != null
        ? sortedHistory.take(limit!).toList()
        : sortedHistory;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (careHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacing_8,
                  ),
                  child: Text(
                    'No care activities have been logged yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final event = displayList[index];
                  final details = _getCareTypeDetails(event.type, context);
                  return IntrinsicHeight(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Container(
                                width: 2,
                                height:
                                    AppTheme.spacing_4 +
                                    AppTheme.spacing_2 /
                                        2, // Adjust height for circle and spacing
                                color: index == 0
                                    ? Colors.transparent
                                    : Theme.of(context).colorScheme.outline,
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: details['color'].withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                child: Icon(
                                  details['icon'],
                                  color: details['color'],
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: index == careHistory.length - 1
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing_4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details['label'],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTheme.spacing_2 / 2),
                              Text(
                                '${DateFormat.yMMMMd().format(event.date)} (${_formatDistanceToNow(event.date)})',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (event.notes != null &&
                                  event.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppTheme.spacing_2,
                                  ),
                                  child: Text(
                                    event.notes!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontStyle: FontStyle.italic),
                                  ),
                                ),
                              const SizedBox(height: AppTheme.spacing_6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
          'label': 'Watered',
          'color': Colors.blue,
        };
      case CareType.fertilizing:
        return {
          'icon': LucideIcons.leaf,
          'label': 'Fertilized',
          'color': Colors.green,
        };
      case CareType.pruning:
        return {
          'icon': LucideIcons.scissors,
          'label': 'Pruned',
          'color': Colors.orange,
        };
    }
  }

  String _formatDistanceToNow(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
