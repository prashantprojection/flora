import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the camera or gallery
  static Future<File?> pickImage({required bool fromCamera}) async {
    final XFile? image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Optimize generic usage natively
    );
    
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}
