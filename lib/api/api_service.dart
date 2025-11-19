
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  final GenerativeModel _model;

  ApiService() :
      _model = GenerativeModel(
        model: 'gemini-pro-vision',
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
      );

  Future<String> diagnosePlant(File image) async {
    try {
      final content = [Content.data('image/jpeg', image.readAsBytesSync())];
      final response = await _model.generateContent(content);
      return response.text ?? 'Could not get diagnosis.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}
