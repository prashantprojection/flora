import 'package:share_plus/share_plus.dart';

class PlatformShareService {
  /// Shares text content natively
  static Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  /// Shares files natively with optional text
  static Future<void> shareFiles(
    List<String> filePaths, {
    String? text,
    String? subject,
    List<String>? mimeTypes,
  }) async {
    final xFiles = filePaths.asMap().entries.map((entry) {
      final index = entry.key;
      final path = entry.value;
      return XFile(
        path,
        mimeType: (mimeTypes != null && index < mimeTypes.length) 
            ? mimeTypes[index] 
            : null,
      );
    }).toList();

    await SharePlus.instance.share(
      ShareParams(
        files: xFiles,
        text: text,
        subject: subject,
      ),
    );
  }
}
