import 'dart:typed_data';
import 'package:flora/api/llm/gemini_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flora/models/llm_models.dart';

abstract class LlmEngine {
  /// Generates a response (text or function call) from a standard prompt
  Future<LlmResponse> generateResponse(String prompt, {LlmConfig? config});

  /// Streams text from a standard prompt for real-time typewriter effect.
  /// (Streaming currently only supports text, not tool calls).
  Stream<String> generateTextStream(String prompt, {LlmConfig? config});

  /// Generates a response in a multi-turn chat context.
  Future<LlmResponse> generateChat(List<LlmMessage> messages, {LlmConfig? config});

  /// Generates a response from an image and an optional prompt
  Future<LlmResponse> generateResponseFromImage(String prompt, Uint8List image, {LlmConfig? config});
}

final llmEngineProvider = Provider<LlmEngine>((ref) {
  // Can be easily swapped to GemmaEngine() if needed for offline support.
  return GeminiEngine();
});
