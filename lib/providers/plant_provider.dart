import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/api/notification_service.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';
import 'package:flora/repositories/plant/plant_repository.dart';
import 'package:flora/repositories/plant/local_plant_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────
// To swap to a remote backend: replace LocalPlantRepository() with
// RemotePlantRepository() — zero other changes needed.

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return LocalPlantRepository();
});

// ── Plant List Notifier ───────────────────────────────────────────────────────

class PlantListNotifier extends Notifier<List<Plant>> {
  PlantRepository get _repository => ref.read(plantRepositoryProvider);

  @override
  List<Plant> build() {
    _loadPlants();
    return [];
  }

  Future<void> _loadPlants() async {
    final plants = await _repository.getPlants();
    state = plants;
  }

  Future<void> _savePlants() async {
    // Unawaited — UI never blocks on disk writes
    _repository.savePlants(state);
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
    final updatedPlant =
        state.firstWhere((p) => p.id == plantId, orElse: () => state.first);
    ref.read(notificationServiceProvider).schedulePlantNotification(updatedPlant);
  }

  Plant _handleCareEvent(Plant plant, CareEvent event) {
    final updatedPlant = plant.copyWith(
      careHistory: [...plant.careHistory, event],
    );
    if (event.type == CareType.watering) {
      final frequency = plant.wateringFrequency ?? 7;
      final nextDate = event.date.add(Duration(days: frequency));
      return updatedPlant.copyWith(
        lastWatered: event.date,
        nextWatering: nextDate,
      );
    } else if (event.type == CareType.skipped ||
        event.type == CareType.snoozed) {
      return updatedPlant;
    } else {
      final scheduleIndex = updatedPlant.careSchedules
          .indexWhere((s) => s.type == event.type);
      if (scheduleIndex != -1) {
        final schedule = updatedPlant.careSchedules[scheduleIndex];
        final nextDate = event.date.add(Duration(days: schedule.frequency));
        final newSchedule = schedule.copyWith(
          lastDate: event.date,
          nextDate: nextDate,
        );
        final newSchedules = List<CareSchedule>.from(updatedPlant.careSchedules);
        newSchedules[scheduleIndex] = newSchedule;
        return updatedPlant.copyWith(careSchedules: newSchedules);
      }
    }
    return updatedPlant;
  }

  void snoozePlantWithDuration(
    String plantId, {
    required int days,
    String? notes,
    CareType type = CareType.watering,
  }) {
    state = [
      for (final plant in state)
        if (plant.id == plantId)
          _snoozePlantInternal(plant, type, days)
        else
          plant,
    ];

    final String eventNote = (notes != null && notes.isNotEmpty)
        ? notes
        : 'Snoozed ${type.name} for $days day(s)';

    addCareEvent(
      plantId,
      CareEvent(
        id: DateTime.now().toString(),
        type: CareType.snoozed,
        date: DateTime.now(),
        notes: eventNote,
      ),
    );
  }

  void snoozePlant(String plantId, {CareType type = CareType.watering}) {
    snoozePlantWithDuration(plantId, days: 1, type: type);
  }

  Plant _snoozePlantInternal(Plant plant, CareType type, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (type == CareType.watering) {
      final baseDate =
          plant.nextWatering.isBefore(today) ? today : plant.nextWatering;
      return plant.copyWith(
        nextWatering: baseDate.add(Duration(days: days)),
      );
    } else {
      final scheduleIndex =
          plant.careSchedules.indexWhere((s) => s.type == type);
      if (scheduleIndex != -1) {
        final schedule = plant.careSchedules[scheduleIndex];
        final baseDate =
            schedule.nextDate.isBefore(today) ? today : schedule.nextDate;
        final newSchedule = schedule.copyWith(
          nextDate: baseDate.add(Duration(days: days)),
        );
        final newSchedules = List<CareSchedule>.from(plant.careSchedules);
        newSchedules[scheduleIndex] = newSchedule;
        return plant.copyWith(careSchedules: newSchedules);
      }
    }
    return plant;
  }

  void skipPlant(String plantId, {CareType type = CareType.watering}) {
    final plant = state.firstWhere((p) => p.id == plantId);
    Plant updatedPlant = plant;

    if (type == CareType.watering) {
      final frequency = plant.wateringFrequency ?? 7;
      final nextDate = DateTime.now().add(Duration(days: frequency));
      updatedPlant = plant.copyWith(nextWatering: nextDate);
    } else {
      final scheduleIndex =
          plant.careSchedules.indexWhere((s) => s.type == type);
      if (scheduleIndex != -1) {
        final schedule = plant.careSchedules[scheduleIndex];
        final nextDate =
            DateTime.now().add(Duration(days: schedule.frequency));
        final newSchedule = schedule.copyWith(nextDate: nextDate);
        final newSchedules = List<CareSchedule>.from(plant.careSchedules);
        newSchedules[scheduleIndex] = newSchedule;
        updatedPlant = plant.copyWith(careSchedules: newSchedules);
      }
    }

    state = [
      for (final p in state)
        if (p.id == plantId) updatedPlant else p,
    ];

    addCareEvent(
      plantId,
      CareEvent(
        id: DateTime.now().toString(),
        type: CareType.skipped,
        date: DateTime.now(),
        notes: 'Skipped ${type.name} task',
      ),
    );
  }

  void updatePlant(Plant updatedPlant) {
    final index = state.indexWhere((p) => p.id == updatedPlant.id);
    if (index != -1) {
      final newPlants = List<Plant>.from(state);
      newPlants[index] = updatedPlant;
      state = newPlants;
      _savePlants();
    }
  }

  void deletePlant(String plantId) {
    state = state.where((p) => p.id != plantId).toList();
    _savePlants();
    ref.read(notificationServiceProvider).cancelPlantNotification(plantId);
  }

  void importPlants(List<Plant> plants, {required String duplicateStrategy}) {
    // Merge logic is business logic — lives here, not in the repository.
    final updated = List<Plant>.from(state);

    for (final plant in plants) {
      final existingIndex = updated.indexWhere((p) => p.id == plant.id);
      if (existingIndex != -1) {
        if (duplicateStrategy == 'replace') {
          updated[existingIndex] = plant;
        } else if (duplicateStrategy == 'keep_both') {
          final newId = '${DateTime.now().millisecondsSinceEpoch}_${plant.id}';
          updated.add(plant.copyWith(id: newId, name: '${plant.name} (Copy)'));
        }
        // 'skip' → do nothing
      } else {
        updated.add(plant);
      }
    }

    state = updated;
    _savePlants();
  }
}

// ── Derived Providers ─────────────────────────────────────────────────────────

final plantListProvider = NotifierProvider<PlantListNotifier, List<Plant>>(
  PlantListNotifier.new,
);

final activeGardenProvider = Provider<List<Plant>>((ref) {
  final plants = ref.watch(plantListProvider);
  return plants
      .where((p) =>
          p.status == PlantStatus.active ||
          p.status == PlantStatus.quarantine ||
          p.status == null)
      .toList();
});

final locationListProvider = Provider<List<String>>((ref) {
  final plants = ref.watch(plantListProvider);
  final defaultLocations = {'Living Room', 'Bedroom', 'Balcony', 'Garden'};
  final plantLocations = plants
      .map((p) => p.location)
      .where((l) => l != null && l.isNotEmpty)
      .cast<String>()
      .toSet();
  final allLocations = {...defaultLocations, ...plantLocations}.toList()
    ..sort();
  return allLocations;
});
