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
      final wateringInterval = plant.nextWatering.difference(plant.lastWatered);
      return updatedPlant.copyWith(
        lastWatered: event.date,
        nextWatering: event.date.add(wateringInterval),
      );
    }
    return updatedPlant;
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
