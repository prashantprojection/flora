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

    Widget imageWidget;
    if (_selectedImageFile != null) {
      imageWidget = Image.file(_selectedImageFile!, fit: BoxFit.cover);
    } else if (_initialImageUrl != null) {
      if (_initialImageUrl!.startsWith('http')) {
        imageWidget = Image.network(
          _initialImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(LucideIcons.flower2, size: 100),
        );
      } else {
        imageWidget = Image.file(
          File(_initialImageUrl!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(LucideIcons.flower2, size: 100),
        );
      }
    } else {
      imageWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.upload,
            size: 40,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: AppTheme.spacing_2),
          Text(
            'Click to upload',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
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
                              isEditing ? 'Edit Plant' : 'Add a New Plant',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacing_2),
                            Text(
                              isEditing
                                  ? "Update the details for your plant."
                                  : "Enter the details for your new plant. Click save when you're done.",
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing_4,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacing_6),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusLg,
                                  ),
                                  child: imageWidget,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Plant Name',
                              hintText: 'e.g., Monty',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a plant name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          TextFormField(
                            controller: _speciesController,
                            decoration: const InputDecoration(
                              labelText: 'Species (Optional)',
                              hintText: 'e.g., Monstera Deliciosa',
                            ),
                            // Removed validator to make it optional
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateController,
                                decoration: const InputDecoration(
                                  labelText: 'Planting Date',
                                  suffixIcon: Icon(LucideIcons.calendar),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a planting date.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location (Optional)',
                              hintText: 'e.g., Living Room Window',
                              prefixIcon: Icon(LucideIcons.mapPin),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing_4),
                          TextFormField(
                            controller: _wateringScheduleController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Watering Schedule (days)',
                              hintText: 'e.g., 7',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a watering schedule.';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return 'Please enter a positive number.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacing_6),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
                                    onPressed: _isSaveEnabled
                                        ? _submitForm
                                        : null,
                                    child: Text(
                                      isEditing ? 'Update Plant' : 'Save Plant',
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
