import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  final GenerativeModel _model;

  ApiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
        );

  Future<String> diagnosePlant(File image) async {
    try {
      final content = [Content.data('image/jpeg', image.readAsBytesSync())];
      final response = await _model.generateContent(content);
      return response.text ?? 'Could not get diagnosis.';
    } catch (e) {
      debugPrint('[ApiService] generateContent failed: $e');
      return 'Error: ${e.toString()}';
    }
  }
}
