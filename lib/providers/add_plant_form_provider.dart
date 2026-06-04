import 'package:flora/utils/app_exception.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/services/ai_service.dart';
import 'package:flora/services/image_service.dart';
import 'package:flora/services/plant_classifier_service.dart';
import 'package:flora/providers/plant_provider.dart';

class AddPlantFormState {
  final bool isGeneratingSuggestions;
  final String? aiReasoning;
  final bool aiSuggestionsApplied;
  final bool isVerifyingImage;
  final String? error;

  const AddPlantFormState({
    this.isGeneratingSuggestions = false,
    this.aiReasoning,
    this.aiSuggestionsApplied = false,
    this.isVerifyingImage = false,
    this.error,
  });

  AddPlantFormState copyWith({
    bool? isGeneratingSuggestions,
    String? aiReasoning,
    bool clearAiReasoning = false,
    bool? aiSuggestionsApplied,
    bool? isVerifyingImage,
    String? error,
    bool clearError = false,
  }) {
    return AddPlantFormState(
      isGeneratingSuggestions: isGeneratingSuggestions ?? this.isGeneratingSuggestions,
      aiReasoning: clearAiReasoning ? null : (aiReasoning ?? this.aiReasoning),
      aiSuggestionsApplied: aiSuggestionsApplied ?? this.aiSuggestionsApplied,
      isVerifyingImage: isVerifyingImage ?? this.isVerifyingImage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AddPlantFormNotifier extends Notifier<AddPlantFormState> {
  @override
  AddPlantFormState build() {
    return const AddPlantFormState();
  }

  Future<Map<String, dynamic>?> getAiSuggestions({
    required String plantName,
    required String species,
    required String location,
    required bool hasGrowLight,
    required String plantStage,
    required String weatherLocation,
  }) async {
    state = state.copyWith(
      isGeneratingSuggestions: true,
      clearAiReasoning: true,
      aiSuggestionsApplied: false,
    );

    try {
      final geminiService = ref.read(aiServiceProvider);
      final recommendations = await geminiService.fetchStructuredCareSchedule(
        plantName: plantName,
        species: species,
        location: location,
        hasGrowLight: hasGrowLight,
        plantStage: plantStage,
        weatherLocation: weatherLocation,
      );

      if (recommendations['isValid'] == false) {
        state = state.copyWith(isGeneratingSuggestions: false);
        return {'isValid': false};
      }

      final rawReasoning = recommendations['reasoning'] as String? ?? '';
      state = state.copyWith(
        isGeneratingSuggestions: false,
        aiReasoning: rawReasoning.isNotEmpty ? rawReasoning : null,
        aiSuggestionsApplied: true,
      );

      return recommendations;
    } on AppException catch (e) {
      state = state.copyWith(isGeneratingSuggestions: false, error: e.message);
      return {'isValid': false};
    } catch (e) {
      state = state.copyWith(isGeneratingSuggestions: false, error: 'An unexpected error occurred.');
      return {'isValid': false};
    }
  }

  Future<bool> verifyPlantImage(XFile file) async {
    state = state.copyWith(isVerifyingImage: true);
    try {
      final classifier = PlantClassifierService();
      final isPlant = await classifier.isPlant(file.path);
      state = state.copyWith(isVerifyingImage: false);
      return isPlant;
    } catch (e) {
      state = state.copyWith(isVerifyingImage: false);
      return false;
    }
  }

  Future<void> submitForm({
    required Plant? existingPlant,
    required String id,
    required String name,
    required String species,
    required String location,
    required DateTime selectedDate,
    required int wateringDays,
    required int? fertilizingDays,
    required int? pruningDays,
    required String careInstructions,
    required PlantStatus plantStatus,
    required PlantStage plantStage,
    required bool hasGrowLight,
    required String weatherLocation,
    required XFile? selectedImageFile,
    required String? initialImageUrl,
  }) async {
    String? imageUrl = initialImageUrl;
    if (selectedImageFile != null) {
      imageUrl = await ImageService.saveImagePermanently(
        selectedImageFile.path,
        prefix: 'plant',
      );
    }

    final DateTime lastWatered = existingPlant?.lastWatered ?? selectedDate;
    final List<CareSchedule> schedules = [];

    void addSchedule(int? days, CareType type) {
      if (days != null && days > 0) {
        final existing = existingPlant?.careSchedules
            .where((s) => s.type == type)
            .firstOrNull;
        final lastDate = existing?.lastDate ?? selectedDate;
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

    addSchedule(fertilizingDays, CareType.fertilizing);
    addSchedule(pruningDays, CareType.pruning);

    final Plant plant = Plant(
      id: id,
      name: name,
      species: species.isEmpty ? null : species,
      imagePath: imageUrl,
      plantingDate: selectedDate,
      location: location,
      lastWatered: lastWatered,
      nextWatering: lastWatered.add(Duration(days: wateringDays)),
      wateringFrequency: wateringDays,
      careInstructions: careInstructions.isEmpty ? null : careInstructions,
      careHistory: existingPlant?.careHistory ?? [],
      careSchedules: schedules,
      status: plantStatus,
      stage: plantStage,
      hasGrowLight: hasGrowLight,
      weatherLocation: weatherLocation.isEmpty ? null : weatherLocation,
      aiReasoning: state.aiSuggestionsApplied ? state.aiReasoning : existingPlant?.aiReasoning,
      aiTipsSource: state.aiSuggestionsApplied ? location : existingPlant?.aiTipsSource,
      aiTipsGeneratedAt: existingPlant?.aiTipsGeneratedAt,
    );

    if (existingPlant == null) {
      ref.read(plantListProvider.notifier).addPlant(plant);
    } else {
      ref.read(plantListProvider.notifier).updatePlant(plant);
    }
  }
}

final addPlantFormProvider = NotifierProvider<AddPlantFormNotifier, AddPlantFormState>(() {
  return AddPlantFormNotifier();
});
