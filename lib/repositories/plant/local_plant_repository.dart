import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/repositories/plant/plant_repository.dart';

/// SharedPreferences-backed implementation of [PlantRepository].
/// Parses and encodes the JSON list off the main thread via [compute].
class LocalPlantRepository implements PlantRepository {
  static const _plantsKey = 'plants';

  @override
  Future<List<Plant>> getPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final String? plantsJson = prefs.getString(_plantsKey);
    if (plantsJson == null || plantsJson.isEmpty) return [];
    return _parsePlants(plantsJson);
  }

  @override
  Future<void> savePlants(List<Plant> plants) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = _encodePlants(plants);
    await prefs.setString(_plantsKey, jsonStr);
  }
}

// ── Isolate helpers (top-level required by compute) ───────────────────────────

List<Plant> _parsePlants(String json) {
  final List<dynamic> decoded = jsonDecode(json);
  return decoded.map((e) => Plant.fromJson(e as Map<String, dynamic>)).toList();
}

String _encodePlants(List<Plant> plants) {
  return jsonEncode(plants.map((p) => p.toJson()).toList());
}
