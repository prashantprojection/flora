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
          backgroundColor: careTypeDetails['color'].withOpacity(0.8),
        ),
      );
      Navigator.of(context).pop();
    }
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
          'label': 'Watered',
          'color': colorScheme.primary,
        };
      case CareType.fertilizing:
        return {
          'icon': LucideIcons.leaf,
          'label': 'Fertilized',
          'color': colorScheme.secondary,
        };
      case CareType.pruning:
        return {
          'icon': LucideIcons.scissors,
          'label': 'Pruned',
          'color': colorScheme.onSurface,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Need theme for Container decoration

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
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
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacing_4,
                    AppTheme.spacing_2,
                    AppTheme.spacing_4,
                    AppTheme.spacing_4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log a Care Activity',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacing_2),
                            Text(
                              'Record a recent care activity for your plant.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  // Added Expanded here
                  child: SingleChildScrollView(
                    controller: scrollController, // Pass the scrollController
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing_4,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ... existing form fields ...
                          const SizedBox(height: AppTheme.spacing_6),
                          DropdownButtonFormField<CareType>(
                            initialValue: _selectedCareType,
                            onChanged: (CareType? newValue) {
                              setState(() {
                                _selectedCareType = newValue!;
                              });
                            },
                            items: CareType.values.map((CareType careType) {
                              return DropdownMenuItem<CareType>(
                                value: careType,
                                child: Row(
                                  children: [
                                    Icon(_getCareTypeIcon(careType)),
                                    const SizedBox(width: AppTheme.spacing_2),
                                    Text(careType.toString().split('.').last),
                                  ],
                                ),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Activity Type',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          TextFormField(
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Activity Date',
                              hintText: DateFormat.yMMMd().format(
                                _selectedDate,
                              ),
                              helperText:
                                  'Leave blank for current date and time',
                              suffixIcon: const Icon(LucideIcons.calendar),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'e.g., Used half-strength fertilizer.',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    textStyle: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing_2),
                              Flexible(
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  child: const Text('Log Activity'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

IconData _getCareTypeIcon(CareType type) {
  switch (type) {
    case CareType.watering:
      return LucideIcons.droplets;
    case CareType.fertilizing:
      return LucideIcons.leaf;
    case CareType.pruning:
      return LucideIcons.scissors;
  }
}
