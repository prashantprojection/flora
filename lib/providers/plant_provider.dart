import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flora/api/api_service.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class PlantListNotifier extends StateNotifier<List<Plant>> {
  PlantListNotifier() : super([]);

  Future<void> loadPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final String? plantsJson = prefs.getString('plants');
    if (plantsJson != null) {
      final List<dynamic> decodedJson = jsonDecode(plantsJson);
      state = decodedJson.map((json) => Plant.fromJson(json)).toList();
    }
  }

  Future<void> _savePlants() async {
    final prefs = await SharedPreferences.getInstance();
    final String plantsJson = jsonEncode(
      state.map((plant) => plant.toJson()).toList(),
    );
    await prefs.setString('plants', plantsJson);
  }

  void addPlant(Plant plant) {
    state = [...state, plant];
    _savePlants();
  }

  void addCareEvent(String plantId, CareEvent event) {
    state = [
      for (final plant in state)
        if (plant.id == plantId) _handleCareEvent(plant, event) else plant,
    ];
    _savePlants();
  }

  Plant _handleCareEvent(Plant plant, CareEvent event) {
    final updatedPlant = plant.copyWith(
      careHistory: [...plant.careHistory, event],
    );
    if (event.type == CareType.watering) {
      // Use the persisted frequency, default to 7 if missing (shouldn't happen with new model)
      final frequency = plant.wateringFrequency ?? 7;
      final nextDate = event.date.add(Duration(days: frequency));

      return updatedPlant.copyWith(
        lastWatered: event.date,
        nextWatering: nextDate,
      );
    } else if (event.type == CareType.skipped) {
      // Logic for skipping: Don't change lastWatered, but push nextWatering to next cycle
      final frequency = plant.wateringFrequency ?? 7;
      final nextDate = DateTime.now().add(Duration(days: frequency));

      return updatedPlant.copyWith(nextWatering: nextDate);
    } else {
      // Handle other care types (fertilizing, pruning)
      final scheduleIndex = updatedPlant.careSchedules.indexWhere(
        (s) => s.type == event.type,
      );
      if (scheduleIndex != -1) {
        final schedule = updatedPlant.careSchedules[scheduleIndex];
        final nextDate = event.date.add(Duration(days: schedule.frequency));
        final newSchedule = schedule.copyWith(
          lastDate: event.date,
          nextDate: nextDate,
        );

        final newSchedules = List<CareSchedule>.from(
          updatedPlant.careSchedules,
        );
        newSchedules[scheduleIndex] = newSchedule;

        return updatedPlant.copyWith(careSchedules: newSchedules);
      }
    }
    return updatedPlant;
  }

  void snoozePlant(String plantId, {CareType type = CareType.watering}) {
    state = [
      for (final plant in state)
        if (plant.id == plantId) _snoozePlantInternal(plant, type) else plant,
    ];
    _savePlants();
  }

  Plant _snoozePlantInternal(Plant plant, CareType type) {
    if (type == CareType.watering) {
      return plant.copyWith(
        nextWatering: plant.nextWatering.add(const Duration(days: 1)),
      );
    } else {
      // Snooze specific schedule
      final scheduleIndex = plant.careSchedules.indexWhere(
        (s) => s.type == type,
      );
      if (scheduleIndex != -1) {
        final schedule = plant.careSchedules[scheduleIndex];
        // Only snooze if it's actually due? Or just push the date?
        // Let's just push the nextDate.
        final newSchedule = schedule.copyWith(
          nextDate: schedule.nextDate.add(const Duration(days: 1)),
        );
        final newSchedules = List<CareSchedule>.from(plant.careSchedules);
        newSchedules[scheduleIndex] = newSchedule;
        return plant.copyWith(careSchedules: newSchedules);
      }
    }
    return plant;
  }

  void skipPlant(String plantId, {CareType type = CareType.watering}) {
    // Log a "skipped" event for today
    // Note: We need to know WHICH type was skipped to reset the correct schedule.
    // Ideally we'd log "skipped_watering" or have metadata.
    // For now, logging CareType.skipped is generic.
    // To properly reset the cycle, we need to know what we skipped.

    // Hack: We'll modify _handleCareEvent to handle "skipped" intelligently if we knew the original intent,
    // BUT generically "skipped" implies skipping the *next due* thing?
    // A specific `skipTask` method is better.

    // Let's just create a generic event but maybe with a note?
    // Or we handle the schedule update HERE directly instead of relying on _handleCareEvent logic for skips.

    final plant = state.firstWhere((p) => p.id == plantId);
    Plant updatedPlant = plant;

    if (type == CareType.watering) {
      final frequency = plant.wateringFrequency ?? 7;
      final nextDate = DateTime.now().add(Duration(days: frequency));
      updatedPlant = plant.copyWith(nextWatering: nextDate);
    } else {
      final scheduleIndex = plant.careSchedules.indexWhere(
        (s) => s.type == type,
      );
      if (scheduleIndex != -1) {
        final schedule = plant.careSchedules[scheduleIndex];
        final nextDate = DateTime.now().add(Duration(days: schedule.frequency));
        final newSchedule = schedule.copyWith(nextDate: nextDate);
        final newSchedules = List<CareSchedule>.from(plant.careSchedules);
        newSchedules[scheduleIndex] = newSchedule;
        updatedPlant = plant.copyWith(careSchedules: newSchedules);
      }
    }

    // Update state directly first (optimistic/logic)
    state = [
      for (final p in state)
        if (p.id == plantId) updatedPlant else p,
    ];

    // Then log the skip event for history
    addCareEvent(
      plantId,
      CareEvent(
        id: DateTime.now().toString(),
        type: CareType.skipped,
        date: DateTime.now(),
        notes: 'Skipped ${type.name}',
      ),
    );
    _savePlants();
  }

  void updatePlant(Plant updatedPlant) {
    final plants = state;
    final index = plants.indexWhere((plant) => plant.id == updatedPlant.id);
    if (index != -1) {
      final newPlants = List<Plant>.from(plants);
      newPlants[index] = updatedPlant;
      state = newPlants;
      _savePlants();
    }
  }

  void deletePlant(String plantId) {
    state = state.where((plant) => plant.id != plantId).toList();
    _savePlants();
  }
}

final plantListProvider = StateNotifierProvider<PlantListNotifier, List<Plant>>(
  (ref) {
    final notifier = PlantListNotifier();
    notifier.loadPlants();
    return notifier;
  },
);
