import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/utils/app_theme.dart';
import 'package:uuid/uuid.dart';

class AddPlantSheet extends ConsumerStatefulWidget {
  final Plant? plant; // Optional plant for editing
  const AddPlantSheet({super.key, this.plant});

  @override
  ConsumerState<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends ConsumerState<AddPlantSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _wateringScheduleController = TextEditingController(text: '7');
  DateTime? _selectedDate;
  File? _selectedImageFile; // Changed name to avoid confusion
  String? _initialImageUrl; // To store the initial image URL/path

  bool _isSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.plant != null) {
      _nameController.text = widget.plant!.name;
      _speciesController.text = widget.plant!.species ?? '';
      _locationController.text = widget.plant!.location ?? '';
      _selectedDate = widget.plant!.plantingDate;
      _dateController.text = DateFormat.yMMMd().format(_selectedDate!);
      if (widget.plant!.nextWatering
              .difference(widget.plant!.lastWatered)
              .inDays >
          0) {
        _wateringScheduleController.text = widget.plant!.nextWatering
            .difference(widget.plant!.lastWatered)
            .inDays
            .toString();
      }

      _initialImageUrl =
          widget.plant!.imageUrl; // Store the original image URL/path
    }
    _nameController.addListener(_validateForm);
    _dateController.addListener(_validateForm);
    _wateringScheduleController.addListener(_validateForm);
    _validateForm(); // Initial validation
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _dateController.removeListener(_validateForm);
    _wateringScheduleController.removeListener(_validateForm);
    _nameController.dispose();
    _speciesController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _wateringScheduleController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final bool isValid =
        _nameController.text.isNotEmpty &&
        _dateController.text.isNotEmpty &&
        (_selectedImageFile != null || _initialImageUrl != null) &&
        (int.tryParse(_wateringScheduleController.text) ?? 0) > 0;
    setState(() {
      _isSaveEnabled = isValid;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _initialImageUrl = null; // Clear initial URL if a new image is picked
      });
      _validateForm();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(data: AppTheme.lightTheme, child: child!);
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMMMd().format(_selectedDate!);
      });
      _validateForm();
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final String id = widget.plant?.id ?? const Uuid().v4();
      final String? imageUrl = _selectedImageFile?.path ?? _initialImageUrl;
      final int wateringDays = int.parse(_wateringScheduleController.text);
      final DateTime lastWatered = widget.plant?.lastWatered ?? _selectedDate!;

      final Plant plant = Plant(
        id: id,
        name: _nameController.text,
        species: _speciesController.text.isEmpty
            ? null
            : _speciesController.text,
        imageUrl: imageUrl,
        plantingDate: _selectedDate!,
        location: _locationController.text,
        lastWatered: lastWatered,
        nextWatering: lastWatered.add(Duration(days: wateringDays)),
        careHistory: widget.plant?.careHistory ?? [],
      );

      if (widget.plant == null) {
        ref.read(plantListProvider.notifier).addPlant(plant);
      } else {
        ref.read(plantListProvider.notifier).updatePlant(plant);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.plant != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
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
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        isEditing ? 'Edit Plant' : 'New Plant',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
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

                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      // Image Picker Section
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  image: _selectedImageFile != null
                                      ? DecorationImage(
                                          image: FileImage(_selectedImageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : (_initialImageUrl != null
                                            ? DecorationImage(
                                                image:
                                                    _initialImageUrl!
                                                        .startsWith('http')
                                                    ? NetworkImage(
                                                        _initialImageUrl!,
                                                      )
                                                    : FileImage(
                                                            File(
                                                              _initialImageUrl!,
                                                            ),
                                                          )
                                                          as ImageProvider,
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child:
                                    (_selectedImageFile == null &&
                                        _initialImageUrl == null)
                                    ? Icon(
                                        LucideIcons.camera,
                                        size: 40,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.pencil,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel(context, 'Basic Info'),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildInputDecoration(
                                context,
                                label: 'Plant Name',
                                hint: 'e.g., Monty',
                                icon: LucideIcons.leaf,
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _speciesController,
                              decoration: _buildInputDecoration(
                                context,
                                label: 'Species (Optional)',
                                hint: 'e.g., Monstera Deliciosa',
                                icon: LucideIcons.sprout,
                              ),
                            ),
                            const SizedBox(height: 24),

                            _buildSectionLabel(context, 'Care Details'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _selectDate(context),
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: _dateController,
                                        decoration: _buildInputDecoration(
                                          context,
                                          label: 'Planted On',
                                          hint: 'Select Date',
                                          icon: LucideIcons.calendar,
                                        ),
                                        validator: (value) =>
                                            (value == null || value.isEmpty)
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              decoration: _buildInputDecoration(
                                context,
                                label: 'Location',
                                hint: 'e.g., Living Room',
                                icon: LucideIcons.mapPin,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _wateringScheduleController,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration(
                                context,
                                label: 'Water Every (days)',
                                hint: 'e.g., 7',
                                icon: LucideIcons.droplets,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final n = int.tryParse(value);
                                if (n == null || n <= 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaveEnabled ? _submitForm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Update Plant' : 'Save Plant',
                            style: const TextStyle(
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
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
      hintText: hint,
      prefixIcon: Icon(
        icon,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
