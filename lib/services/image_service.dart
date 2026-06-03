import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the camera or gallery
  static Future<XFile?> pickImage({required bool fromCamera}) async {
    return await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Optimize generic usage natively
    );
  }

  /// Copies a temporary image to the app's persistent document directory.
  /// If it's already persistent, returns the original path.
  static Future<String> saveImagePermanently(String temporaryPath, {String prefix = 'img'}) async {
    if (temporaryPath.contains('app_flutter')) {
      return temporaryPath;
    }
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = '${prefix}_${const Uuid().v4()}.jpg';
      final savedImage = await File(temporaryPath).copy('${docsDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      return temporaryPath;
    }
  }
}
