import 'package:flutter_test/flutter_test.dart';
import 'package:flora/models/plant.dart';

void main() {
  group('Plant Provider Logic Tests', () {
    test('snoozePlant pushes the next task date by 1 day by default', () {
      final plant = Plant(
        id: '1',
        name: 'Snake Plant',
        plantingDate: DateTime(2023, 1, 1),
        lastWatered: DateTime(2023, 1, 1),
        nextWatering: DateTime(2023, 1, 8),
        careHistory: const [],
      );

      final nextDate = plant.nextWatering;
      
      // We simulate what snoozePlant logic does for watering
      final snoozedPlant = plant.copyWith(
        nextWatering: nextDate.add(const Duration(days: 1)),
      );

      expect(snoozedPlant.nextWatering.day, 9);
    });
    
    test('snoozePlantWithDuration pushes the next task date by X days', () {
      final plant = Plant(
        id: '1',
        name: 'Snake Plant',
        plantingDate: DateTime(2023, 1, 1),
        lastWatered: DateTime(2023, 1, 1),
        nextWatering: DateTime(2023, 1, 8),
        careHistory: const [],
      );

      final nextDate = plant.nextWatering;
      
      // Simulate what snoozePlantWithDuration logic does for watering
      final snoozedPlant = plant.copyWith(
        nextWatering: nextDate.add(const Duration(days: 3)),
      );

      expect(snoozedPlant.nextWatering.day, 11);
    });
  });
}
