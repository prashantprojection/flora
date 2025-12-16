import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/utils/app_theme.dart'; // Added import

class LogCareSheet extends ConsumerStatefulWidget {
  // Renamed class
  final String plantId;

  const LogCareSheet({super.key, required this.plantId});

  @override
  ConsumerState<LogCareSheet> createState() => _LogCareSheetState(); // Renamed state class
}

class _LogCareSheetState extends ConsumerState<LogCareSheet> {
  // Renamed state class
  final _formKey = GlobalKey<FormState>();
  CareType _selectedCareType = CareType.watering;
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        // Added builder for theme
        return Theme(data: AppTheme.lightTheme, child: child!);
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newCareEvent = CareEvent(
        id: DateTime.now().toString(),
        type: _selectedCareType,
        date: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      ref
          .read(plantListProvider.notifier)
          .addCareEvent(widget.plantId, newCareEvent);

      final careTypeDetails = _getCareTypeDetails(_selectedCareType, context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Care activity logged: ${careTypeDetails['label']}'),
          backgroundColor: careTypeDetails['color'].withValues(alpha: 0.8),
        ),
      );
      Navigator.of(context).pop();
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Text(
                        'Log Care',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                        style: IconButton.styleFrom(
                          backgroundColor: theme
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      Text(
                        'WHAT DID YOU DO TODAY?',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: CareType.values.map((type) {
                          final isSelected = _selectedCareType == type;
                          final details = _getCareTypeDetails(type, context);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCareType = type;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? details['color'].withValues(alpha: 0.15)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? details['color']
                                        : theme.colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      details['icon'],
                                      color: isSelected
                                          ? details['color']
                                          : theme.colorScheme.onSurfaceVariant,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      type
                                              .toString()
                                              .split('.')
                                              .last[0]
                                              .toUpperCase() +
                                          type
                                              .toString()
                                              .split('.')
                                              .last
                                              .substring(1),
                                      style: TextStyle(
                                        color: isSelected
                                            ? details['color']
                                            : theme.colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              controller: TextEditingController(
                                text: _isToday(_selectedDate)
                                    ? 'Today, ${DateFormat.yMMMd().format(_selectedDate)}'
                                    : DateFormat.yMMMd().format(_selectedDate),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Date',
                                prefixIcon: const Icon(LucideIcons.calendar),
                                suffixIcon: const Icon(
                                  LucideIcons.chevronDown,
                                  size: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Notes',
                                hintText: 'Any observations?',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Log Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
