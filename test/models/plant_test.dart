import 'package:flutter_test/flutter_test.dart';
import 'package:flora/models/plant.dart';
import 'package:flora/models/care_event.dart';

void main() {
  group('Plant Model Tests', () {
    test('fromJson assigns default values for missing new fields', () {
      final json = {
        'id': '123',
        'name': 'Ficus',
        'plantingDate': '2023-01-01T00:00:00.000Z',
        'lastWatered': '2023-01-01T00:00:00.000Z',
        'nextWatering': '2023-01-08T00:00:00.000Z',
        'wateringFrequency': 7,
        'careHistory': [],
      };

      final plant = Plant.fromJson(json);

      expect(plant.id, '123');
      expect(plant.name, 'Ficus');
      expect(plant.status, PlantStatus.active);
      expect(plant.stage, PlantStage.mature);
      expect(plant.hasGrowLight, false);
      expect(plant.weatherLocation, isNull);
    });

    test('fromJson parses new fields correctly', () {
      final json = {
        'id': '123',
        'name': 'Ficus',
        'plantingDate': '2023-01-01T00:00:00.000Z',
        'lastWatered': '2023-01-01T00:00:00.000Z',
        'nextWatering': '2023-01-08T00:00:00.000Z',
        'wateringFrequency': 7,
        'careHistory': [],
        'status': 'PlantStatus.quarantine',
        'stage': 'PlantStage.seedling',
        'hasGrowLight': true,
        'weatherLocation': 'New York, NY',
      };

      final plant = Plant.fromJson(json);

      expect(plant.status, PlantStatus.quarantine);
      expect(plant.stage, PlantStage.seedling);
      expect(plant.hasGrowLight, true);
      expect(plant.weatherLocation, 'New York, NY');
    });

    test('toJson includes new fields', () {
      final plant = Plant(
        id: '123',
        name: 'Ficus',
        plantingDate: DateTime(2023, 1, 1),
        lastWatered: DateTime(2023, 1, 1),
        nextWatering: DateTime(2023, 1, 8),
        careHistory: const [],
        status: PlantStatus.quarantine,
        stage: PlantStage.seedling,
        hasGrowLight: true,
        weatherLocation: 'New York, NY',
      );

      final json = plant.toJson();

      expect(json['status'], 'PlantStatus.quarantine');
      expect(json['stage'], 'PlantStage.seedling');
      expect(json['hasGrowLight'], true);
      expect(json['weatherLocation'], 'New York, NY');
    });

    test('copyWith updates fields', () {
      final plant = Plant(
        id: '123',
        name: 'Ficus',
        plantingDate: DateTime(2023, 1, 1),
        lastWatered: DateTime(2023, 1, 1),
        nextWatering: DateTime(2023, 1, 8),
        careHistory: const [],
      );

      final updated = plant.copyWith(
        status: PlantStatus.givenAway,
        stage: PlantStage.cutting,
        hasGrowLight: true,
        weatherLocation: 'Seattle',
      );

      expect(updated.status, PlantStatus.givenAway);
      expect(updated.stage, PlantStage.cutting);
      expect(updated.hasGrowLight, true);
      expect(updated.weatherLocation, 'Seattle');
    });
  });
}
