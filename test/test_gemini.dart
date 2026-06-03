// ignore_for_file: avoid_print

import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null) {
    print('API key not found');
    return;
  }
  
  try {
    print('Testing gemini-2.5-flash with key starting with ${apiKey.substring(0, 5)}...');
    final model25 = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    final response = await model25.generateContent([Content.text('Hello')]);
    print('Response 2.5: ${response.text}');
  } catch (e, stacktrace) {
    print('Error with 2.5: $e');
    print('Stacktrace: $stacktrace');
  }
}
