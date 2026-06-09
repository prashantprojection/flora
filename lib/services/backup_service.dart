import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flora/services/platform_share_service.dart';
import 'package:flora/models/plant.dart';

class BackupService {
  static Future<void> exportBackup(List<Plant> plants) async {
    final listJson = plants.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(listJson);

    final directory = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('${directory.path}/flora_backup_$dateStr.json');
    await file.writeAsString(jsonString);

    await PlatformShareService.shareFiles(
      [file.path],
      mimeTypes: ['application/json'],
      subject: 'Flora Garden Backup',
      text: 'Here is my Flora garden backup!',
    );
  }

  static List<Plant> parseBackup(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is List) {
      return decoded
          .map((item) => Plant.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Invalid backup format. Must be a list of plants.');
  }
}
