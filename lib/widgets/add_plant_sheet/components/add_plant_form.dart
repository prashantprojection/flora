import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/widgets/custom_dropdown_button.dart';

class AddPlantForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController speciesController;
  final TextEditingController locationController;
  final TextEditingController dateController;
  final TextEditingController wateringScheduleController;
  final TextEditingController fertilizingScheduleController;
  final TextEditingController pruningScheduleController;
  final TextEditingController careInstructionsController;

  final bool isOnline;
  final bool showAiTooltip;
  final bool isGeneratingSuggestions;
  final bool aiSuggestionsApplied;
  final String? aiReasoning;

  final VoidCallback onDismissAiTooltip;
  final VoidCallback onGetAiSuggestions;
  final VoidCallback onSelectDate;
  final bool isOtherSelected;
  final ValueChanged<bool> onIsOtherSelectedChanged;
  final ValueChanged<String?> onLocationChanged;

  const AddPlantForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.speciesController,
    required this.locationController,
    required this.dateController,
    required this.wateringScheduleController,
    required this.fertilizingScheduleController,
    required this.pruningScheduleController,
    required this.careInstructionsController,
    required this.isOnline,
    required this.showAiTooltip,
    required this.isGeneratingSuggestions,
    required this.aiSuggestionsApplied,
    required this.aiReasoning,
    required this.onDismissAiTooltip,
    required this.onGetAiSuggestions,
    required this.onSelectDate,
    required this.isOtherSelected,
    required this.onIsOtherSelectedChanged,
    required this.onLocationChanged,
    required this.isEditing,
    required this.plantStage,
    required this.onStageChanged,
    required this.plantStatus,
    required this.onStatusChanged,
    required this.hasGrowLight,
    required this.onGrowLightChanged,
    required this.weatherLocationController,
  });

  final bool isEditing;
  final PlantStage plantStage;
  final ValueChanged<PlantStage> onStageChanged;
  final PlantStatus plantStatus;
  final ValueChanged<PlantStatus> onStatusChanged;
  final bool hasGrowLight;
  final ValueChanged<bool> onGrowLightChanged;
  final TextEditingController weatherLocationController;

  @override
  State<AddPlantForm> createState() => _AddPlantFormState();
}

class _AddPlantFormState extends State<AddPlantForm> {
  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.1,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD 1: IDENTITY
          _buildSectionLabel(context, 'Identity'),
          _buildCard(
            child: Column(
              children: [
                TextFormField(
                  controller: widget.nameController,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Plant Name',
                    hint: 'e.g., Monty',
                    icon: LucideIcons.leaf,
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: widget.speciesController,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Species (Optional)',
                    hint: 'e.g., Monstera Deliciosa',
                    icon: LucideIcons.sprout,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final locations = ref.watch(locationListProvider);
                    final dropdownItems = [...locations, 'Other'];
                    String? dropdownValue;

                    if (widget.isOtherSelected) {
                      dropdownValue = 'Other';
                    } else if (widget.locationController.text.isNotEmpty &&
                        locations.contains(widget.locationController.text)) {
                      dropdownValue = widget.locationController.text;
                    } else if (widget.locationController.text.isNotEmpty) {
                      dropdownValue = 'Other';
                    }

                    return Column(
                      children: [
                        CustomDropdownButton<String>(
                          value: dropdownValue,
                          label: 'Location',
                          hint: 'Select Location',
                          icon: LucideIcons.mapPin,
                          items: dropdownItems,
                          itemLabelBuilder: (loc) => loc,
                          onChanged: (value) {
                            if (value == 'Other') {
                              widget.onIsOtherSelectedChanged(true);
                              if (locations.contains(
                                widget.locationController.text,
                              )) {
                                widget.locationController.clear();
                              }
                            } else {
                              widget.onIsOtherSelectedChanged(false);
                              widget.locationController.text = value ?? '';
                              widget.onLocationChanged(value);
                            }
                          },
                        ),
                        if (dropdownValue == 'Other') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: widget.locationController,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              context,
                              label: 'Custom Location',
                              hint: 'e.g., Sunroom',
                              icon: LucideIcons.mapPin,
                            ),
                            onChanged: (value) =>
                                widget.onLocationChanged(value),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                CustomDropdownButton<PlantStage>(
                  value: widget.plantStage,
                  label: 'Growth Stage',
                  hint: 'Select stage',
                  icon: LucideIcons.sprout,
                  items: PlantStage.values,
                  itemLabelBuilder: (stage) =>
                      stage.name[0].toUpperCase() + stage.name.substring(1),
                  onChanged: (val) {
                    if (val != null) widget.onStageChanged(val);
                  },
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 16),
                  CustomDropdownButton<PlantStatus>(
                    value: widget.plantStatus,
                    label: 'Plant Status',
                    hint: 'Select status',
                    icon: LucideIcons.activity,
                    items: PlantStatus.values,
                    itemLabelBuilder: (status) {
                      const statusNames = {
                        PlantStatus.active: 'Active',
                        PlantStatus.quarantine: 'Quarantine',
                        PlantStatus.givenAway: 'Given Away',
                        PlantStatus.deceased: 'Deceased',
                      };
                      return statusNames[status]!;
                    },
                    onChanged: (val) {
                      if (val != null) widget.onStatusChanged(val);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CARD 2: SMART CARE & SCHEDULES
          _buildSectionLabel(context, 'Smart Care & Schedules'),
          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Grow Light'),
                  subtitle: const Text('Plant is kept under a grow light'),
                  secondary: Icon(
                    LucideIcons.lamp,
                    color: theme.colorScheme.primary,
                  ),
                  value: widget.hasGrowLight,
                  onChanged: widget.onGrowLightChanged,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: widget.weatherLocationController,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Weather Location (Optional)',
                    hint: 'City or Zip Code for climate advice',
                    icon: LucideIcons.cloudSun,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.showAiTooltip)
                  GestureDetector(
                    onTap: widget.onDismissAiTooltip,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Flo AI generates a personalised watering schedule based on your plant species and location — not a generic database.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.x,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                Tooltip(
                  message: widget.isOnline
                      ? ''
                      : 'Offline — Flo AI is unavailable',
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed:
                          (!widget.isOnline || widget.isGeneratingSuggestions)
                          ? null
                          : widget.onGetAiSuggestions,
                      icon: widget.isGeneratingSuggestions
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              LucideIcons.sparkles,
                              color: widget.isOnline
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                            ),
                      label: Text(
                        widget.isGeneratingSuggestions
                            ? 'Asking Flo...'
                            : 'Auto-Suggest Schedule & Tips',
                        style: TextStyle(
                          color: widget.isOnline
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: widget.isOnline
                            ? theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.3,
                              )
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!widget.isOnline) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.wifiOff,
                        size: 12,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Flo AI unavailable offline',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                _ScheduleCounterField(
                  controller: widget.wateringScheduleController,
                  label: 'Watering',
                  hint: 'Days between watering',
                  icon: LucideIcons.droplets,
                  isRequired: true,
                ),

                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: ValueKey(widget.aiSuggestionsApplied),
                    initiallyExpanded: widget.aiSuggestionsApplied,
                    title: Text(
                      'Advanced Schedules',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      _ScheduleCounterField(
                        controller: widget.fertilizingScheduleController,
                        label: 'Fertilizing',
                        hint: 'Days between fertilizing',
                        icon: LucideIcons.flaskConical,
                      ),
                      const SizedBox(height: 16),
                      _ScheduleCounterField(
                        controller: widget.pruningScheduleController,
                        label: 'Pruning',
                        hint: 'Days between pruning',
                        icon: LucideIcons.scissors,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                if (widget.aiSuggestionsApplied) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.sparkles,
                        size: 12,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Suggested by Flo AI for ${widget.nameController.text}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (widget.aiReasoning?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Flo\'s Analysis',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.aiReasoning!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer
                                      .withValues(alpha: 0.9),
                                  height: 1.5,
                                ),
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
          const SizedBox(height: 24),

          // CARD 3: DETAILS
          _buildSectionLabel(context, 'Details'),
          _buildCard(
            child: Column(
              children: [
                GestureDetector(
                  onTap: widget.onSelectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Planted On',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.dateController.text.isEmpty
                                    ? 'Select Date'
                                    : widget.dateController.text,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: widget.careInstructionsController,
                  maxLines: 4,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Care Instructions / Notes',
                    hint: 'Seasonal tips and general advice...',
                    icon: LucideIcons.alignLeft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCounterField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isRequired;

  const _ScheduleCounterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = false,
  });

  @override
  State<_ScheduleCounterField> createState() => _ScheduleCounterFieldState();
}

class _ScheduleCounterFieldState extends State<_ScheduleCounterField> {
  int _value = 0;

  @override
  void initState() {
    super.initState();
    _updateValueFromController();
    widget.controller.addListener(_updateValueFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateValueFromController);
    super.dispose();
  }

  void _updateValueFromController() {
    final newValue = int.tryParse(widget.controller.text) ?? 0;
    if (_value != newValue && mounted) {
      setState(() => _value = newValue);
    }
  }

  void _increment() {
    final newValue = _value + 1;
    widget.controller.text = newValue.toString();
  }

  void _decrement() {
    if (_value > 0) {
      final newValue = _value - 1;
      widget.controller.text = newValue == 0 && !widget.isRequired
          ? ''
          : newValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.isRequired && _value == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                  ),
                ),
                Text(
                  widget.hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.minus, size: 16),
                  onPressed: _value > (widget.isRequired ? 1 : 0)
                      ? _decrement
                      : null,
                  color: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    _value > 0 ? '$_value' : '-',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 16),
                  onPressed: _increment,
                  color: theme.colorScheme.primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
