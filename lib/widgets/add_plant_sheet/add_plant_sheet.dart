import 'dart:io';

import 'package:flora/models/care_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/providers/plant_provider.dart';
import 'package:flora/utils/app_theme.dart';
import 'package:flora/services/ai_service.dart';
import 'package:flora/services/plant_classifier_service.dart';
import 'package:flora/providers/connectivity_provider.dart';
import 'package:flora/services/preferences_service.dart';
import 'package:uuid/uuid.dart';

import 'package:flora/widgets/add_plant_sheet/components/add_plant_image_picker.dart';
import 'package:flora/widgets/add_plant_sheet/components/add_plant_form.dart';

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
  final _wateringScheduleController = TextEditingController();
  final _fertilizingScheduleController = TextEditingController();
  final _pruningScheduleController = TextEditingController();
  final _careInstructionsController = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImageFile;
  String? _initialImageUrl;

  bool _isSaveEnabled = false;
  bool _isGeneratingSuggestions = false;
  bool _isOtherSelected = false;

  bool _hasGrowLight = false;
  PlantStage _plantStage = PlantStage.mature;
  PlantStatus _plantStatus = PlantStatus.active;
  final _weatherLocationController = TextEditingController();

  // AI reasoning state
  String? _aiReasoning;
  // Track whether AI suggestions have been applied
  bool _aiSuggestionsApplied = false;
  // One-time tooltip
  bool _showAiTooltip = false;

  @override
  void initState() {
    super.initState();
    if (widget.plant != null) {
      _nameController.text = widget.plant!.name;
      _speciesController.text = widget.plant!.species ?? '';
      _locationController.text = widget.plant!.location ?? '';
      _selectedDate = widget.plant!.plantingDate;
      _dateController.text = DateFormat.yMMMd().format(_selectedDate!);

      // Watering (Migration/Fallback logic is in Plant model now, but safe to default)
      if (widget.plant!.wateringFrequency != null) {
        _wateringScheduleController.text = widget.plant!.wateringFrequency
            .toString();
      }

      // Load specific schedules
      final fertilizing = widget.plant!.careSchedules
          .where((s) => s.type == CareType.fertilizing)
          .firstOrNull;
      if (fertilizing != null) {
        _fertilizingScheduleController.text = fertilizing.frequency.toString();
      }

      final pruning = widget.plant!.careSchedules
          .where((s) => s.type == CareType.pruning)
          .firstOrNull;
      if (pruning != null) {
        _pruningScheduleController.text = pruning.frequency.toString();
      }

      _initialImageUrl = widget.plant!.imagePath;
      if (widget.plant!.careInstructions != null) {
        _careInstructionsController.text = widget.plant!.careInstructions!;
      }
      _hasGrowLight = widget.plant!.hasGrowLight;
      _plantStage = widget.plant!.stage ?? PlantStage.mature;
      _plantStatus = widget.plant!.status ?? PlantStatus.active;
      _weatherLocationController.text = widget.plant!.weatherLocation ?? '';
    }
    _nameController.addListener(_validateForm);
    _dateController.addListener(_validateForm);
    _wateringScheduleController.addListener(_validateForm);
    _validateForm();
    _checkAiTooltip();
  }

  Future<void> _checkAiTooltip() async {
    final shown = PreferencesService.hasSeenAiTooltip;
    if (!shown && mounted) {
      setState(() => _showAiTooltip = true);
    }
  }

  Future<void> _dismissAiTooltip() async {
    await PreferencesService.setHasSeenAiTooltip(true);
    if (mounted) setState(() => _showAiTooltip = false);
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
    _fertilizingScheduleController.dispose();
    _pruningScheduleController.dispose();
    _careInstructionsController.dispose();
    _weatherLocationController.dispose();
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
    final pickedFile = await ImageService.pickImage(fromCamera: false);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = pickedFile;
        _initialImageUrl = null;
      });
      _validateForm();
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await ImageService.pickImage(fromCamera: true);

    if (pickedFile != null) {
      final file = pickedFile;

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Verifying image...')));
      }

      // Validate if it's a plant
      final classifier = PlantClassifierService();
      final isPlant = await classifier.isPlant(file.path);

      if (mounted) {
        if (isPlant) {
          setState(() {
            _selectedImageFile = file;
            _initialImageUrl = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plant verified and photo set!')),
          );
          _validateForm();
        } else {
          _showNonPlantDialog(file);
        }
      }
    }
  }

  void _showNonPlantDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not a Plant?'),
        content: const Text(
          'This doesn\'t look like a plant. Do you want to use this photo anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Retake'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedImageFile = file;
                _initialImageUrl = null;
              });
              Navigator.of(context).pop();
              _validateForm();
            },
            child: const Text('Use Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
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

  Future<void> _getAiSuggestions() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plant name first.')),
      );
      return;
    }

    // Location is required for climate-aware suggestions
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your location first to get climate-aware tips.'),
        ),
      );
      return;
    }

    // Dismiss the one-time tooltip when first used
    if (_showAiTooltip) _dismissAiTooltip();

    setState(() {
      _isGeneratingSuggestions = true;
      _aiReasoning = null;
      _aiSuggestionsApplied = false;
    });

    try {
      final geminiService = ref.read(aiServiceProvider);
      final recommendations = await geminiService.getPlantCareRecommendations(
        plantName: _nameController.text,
        species: _speciesController.text,
        location: _locationController.text,
        hasGrowLight: _hasGrowLight,
        plantStage: _plantStage.name,
        weatherLocation: _weatherLocationController.text,
      );

      if (mounted) {
        if (recommendations['isValid'] == false) {
          setState(() {
            _isGeneratingSuggestions = false;
          });
          _showInvalidPlantDialog(_nameController.text);
          return;
        }

        setState(() {
          _wateringScheduleController.text =
              recommendations['wateringFrequency'].toString();
              
          final int fert = recommendations['fertilizingFrequency'] ?? 0;
          if (fert > 0) {
            _fertilizingScheduleController.text = fert.toString();
          }
          
          final int prune = recommendations['pruningFrequency'] ?? 0;
          if (prune > 0) {
            _pruningScheduleController.text = prune.toString();
          }
          
          _careInstructionsController.text = recommendations['advice'] ?? '';
          // Store AI reasoning
          final rawReasoning = recommendations['reasoning'] as String? ?? '';
          _aiReasoning = rawReasoning.isNotEmpty ? rawReasoning : null;
          // Mark that suggestions were AI-applied
          _aiSuggestionsApplied = true;
        });
        _validateForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get suggestions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSuggestions = false;
        });
      }
    }
  }

  void _showInvalidPlantDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plant Not Recognized'),
        content: Text(
          'We couldn\'t identify "$name" as a known plant.\n\nPlease check the spelling or enter details manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String id = widget.plant?.id ?? const Uuid().v4();
      
      String? imageUrl = _initialImageUrl;
      if (_selectedImageFile != null) {
        imageUrl = await ImageService.saveImagePermanently(
          _selectedImageFile!.path,
          prefix: 'plant',
        );
      }

      final int wateringDays = int.parse(_wateringScheduleController.text);
      final DateTime lastWatered = widget.plant?.lastWatered ?? _selectedDate!;

      // Handle additional schedules
      final List<CareSchedule> schedules = [];

      void addSchedule(TextEditingController controller, CareType type) {
        if (controller.text.isNotEmpty) {
          final int? days = int.tryParse(controller.text);
          if (days != null && days > 0) {
            final existing = widget.plant?.careSchedules
                .where((s) => s.type == type)
                .firstOrNull;
            final lastDate = existing?.lastDate ?? _selectedDate!;
            final nextDate = lastDate.add(Duration(days: days));
            schedules.add(
              CareSchedule(
                type: type,
                frequency: days,
                lastDate: lastDate,
                nextDate: nextDate,
              ),
            );
          }
        }
      }

      addSchedule(_fertilizingScheduleController, CareType.fertilizing);
      addSchedule(_pruningScheduleController, CareType.pruning);

      final Plant plant = Plant(
        id: id,
        name: _nameController.text,
        species: _speciesController.text.isEmpty
            ? null
            : _speciesController.text,
        imagePath: imageUrl,
        plantingDate: _selectedDate!,
        location: _locationController.text,
        lastWatered: lastWatered,
        nextWatering: lastWatered.add(Duration(days: wateringDays)),
        wateringFrequency: wateringDays,
        careInstructions: _careInstructionsController.text.isEmpty
            ? null
            : _careInstructionsController.text,
        careHistory: widget.plant?.careHistory ?? [],
        careSchedules: schedules,
        status: _plantStatus,
        stage: _plantStage,
        hasGrowLight: _hasGrowLight,
        weatherLocation: _weatherLocationController.text.isEmpty ? null : _weatherLocationController.text,
        // Persist AI reasoning if suggestions were applied
        aiReasoning: _aiSuggestionsApplied ? _aiReasoning : widget.plant?.aiReasoning,
        // Store location source
        aiTipsSource: _aiSuggestionsApplied
            ? _locationController.text
            : widget.plant?.aiTipsSource,
        // Preserve existing aiTipsGeneratedAt
        aiTipsGeneratedAt: widget.plant?.aiTipsGeneratedAt,
      );

      if (widget.plant == null) {
        ref.read(plantListProvider.notifier).addPlant(plant);
      } else {
        ref.read(plantListProvider.notifier).updatePlant(plant);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.plant != null;
    final isOnline = ref.watch(isOnlineProvider);

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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    children: [
                      AddPlantImagePicker(
                        selectedImageFile: _selectedImageFile,
                        initialImageUrl: _initialImageUrl,
                        onPickImage: _pickImage,
                        onTakePhoto: _takePhoto,
                      ),
                      const SizedBox(height: 24),

                      AddPlantForm(
                        formKey: _formKey,
                        nameController: _nameController,
                        speciesController: _speciesController,
                        locationController: _locationController,
                        dateController: _dateController,
                        wateringScheduleController: _wateringScheduleController,
                        fertilizingScheduleController: _fertilizingScheduleController,
                        pruningScheduleController: _pruningScheduleController,
                        careInstructionsController: _careInstructionsController,
                        isOnline: isOnline,
                        showAiTooltip: _showAiTooltip,
                        isGeneratingSuggestions: _isGeneratingSuggestions,
                        aiSuggestionsApplied: _aiSuggestionsApplied,
                        aiReasoning: _aiReasoning,
                        onDismissAiTooltip: _dismissAiTooltip,
                        onGetAiSuggestions: _getAiSuggestions,
                        onSelectDate: _selectDate,
                        isOtherSelected: _isOtherSelected,
                        onIsOtherSelectedChanged: (value) => setState(() => _isOtherSelected = value),
                        onLocationChanged: (value) => setState(() {}),
                        isEditing: isEditing,
                        plantStage: _plantStage,
                        onStageChanged: (val) => setState(() => _plantStage = val),
                        plantStatus: _plantStatus,
                        onStatusChanged: (val) => setState(() => _plantStatus = val),
                        hasGrowLight: _hasGrowLight,
                        onGrowLightChanged: (val) => setState(() => _hasGrowLight = val),
                        weatherLocationController: _weatherLocationController,
                      ),
                    ],
                  ),
                ),
                
                // Sticky bottom action bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24, 
                    16, 
                    24, 
                    16 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaveEnabled ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
