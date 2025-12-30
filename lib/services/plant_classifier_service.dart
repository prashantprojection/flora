import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter/foundation.dart';

class PlantClassifierService {
  // A whitelist of labels that suggest the image contains a plant or plant part.
  static const List<String> _validLabels = [
    'Plant',
    'Tree',
    'Flower',
    'Leaf',
    'Vegetable',
    'Grass',
    'Herb',
    'Flora',
    'Houseplant',
    'Potted plant',
    'Flowering plant',
    'Shrub',
    'Branch',
    'Vase', // Often contains flowers
    'Petal',
    'Botany',
  ];

  /// Analyzes the image at [imagePath] and returns true if it likely contains a plant.
  /// Uses Google ML Kit's on-device Image Labeling.
  Future<bool> isPlant(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);

    // Confidence threshold: 0.5 is a good balance.
    // We don't want to be too strict, just filter out obvious non-plants (shoes, cars).
    final ImageLabelerOptions options = ImageLabelerOptions(
      confidenceThreshold: 0.5,
    );
    final imageLabeler = ImageLabeler(options: options);

    try {
      final List<ImageLabel> labels = await imageLabeler.processImage(
        inputImage,
      );

      if (kDebugMode) {
        print(
          'ML Kit Labels found: ${labels.map((e) => '${e.label} (${e.confidence.toStringAsFixed(2)})').join(', ')}',
        );
      }

      for (ImageLabel label in labels) {
        // Check if the label (or a part of it) matches our whitelist
        // We use a case-insensitive check.
        if (_validLabels.any(
          (valid) => label.label.toLowerCase().contains(valid.toLowerCase()),
        )) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // If classification fails for some reason, default to allowing the image
      // (fail open) so we don't block the user unnecessarily.
      debugPrint('Error during plant classification: $e');
      return true;
    } finally {
      imageLabeler.close();
    }
  }

  /// Returns the most confident label if it matches a plant, or null.
  Future<String?> getBestPlantLabel(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final ImageLabelerOptions options = ImageLabelerOptions(
      confidenceThreshold: 0.5,
    );
    final imageLabeler = ImageLabeler(options: options);

    try {
      final List<ImageLabel> labels = await imageLabeler.processImage(
        inputImage,
      );

      // Filter for valid plant labels
      final plantLabels = labels
          .where(
            (l) => _validLabels.any(
              (valid) => l.label.toLowerCase().contains(valid.toLowerCase()),
            ),
          )
          .toList();

      if (plantLabels.isNotEmpty) {
        // Return the one with highest confidence
        plantLabels.sort((a, b) => b.confidence.compareTo(a.confidence));
        return plantLabels.first.label;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting best plant label: $e');
      return null;
    } finally {
      imageLabeler.close();
    }
  }
}
