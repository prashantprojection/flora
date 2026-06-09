import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleCalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool Function(DateTime) hasTasksForDate;

  const ScheduleCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.hasTasksForDate,
  });

  @override
  State<ScheduleCalendarStrip> createState() => _ScheduleCalendarStripState();
}

class _ScheduleCalendarStripState extends State<ScheduleCalendarStrip> {
  late final ScrollController _scrollController;
  late final List<DateTime> _dates;
  final double _itemWidth = 56.0; // 48 width + 8 margin

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(ScheduleCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selectedDate.isAtSameMomentAs(widget.selectedDate)) {
      _scrollToSelectedDate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generateDates() {
    final today = DateTime.now();
    _dates = List.generate(14, (index) => today.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _scrollToSelectedDate() {
    if (!_scrollController.hasClients) return;

    final index = _dates.indexWhere((d) => _isSameDay(d, widget.selectedDate));
    if (index != -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Calculate offset to center the item
      final offset =
          (index * _itemWidth) + 16.0 - (screenWidth / 2) + (_itemWidth / 2);
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = offset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return SizedBox(
      height: 82,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isSameDay(date, today);
          final hasTasks = widget.hasTasksForDate(date);

          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : (isToday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Task/Today indicator dot
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : (isToday
                                ? theme.colorScheme.primary
                                : (hasTasks
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.5,
                                        )
                                      : Colors.transparent)),
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
}
