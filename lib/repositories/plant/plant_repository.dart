import 'package:flora/models/plant.dart';

/// Abstract contract for plant data persistence.
/// Repository = CRUD only. Business logic (merge strategies, scheduling, etc.)
/// lives in [PlantListNotifier], not here.
///
/// Swap [LocalPlantRepository] for [RemotePlantRepository] with zero UI changes.
abstract class PlantRepository {
  /// Returns all persisted plants. Empty list if none found.
  Future<List<Plant>> getPlants();

  /// Atomically replaces the full persisted plant list.
  Future<void> savePlants(List<Plant> plants);
}
