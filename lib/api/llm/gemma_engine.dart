import 'package:flutter/foundation.dart';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';

class GemmaEngine implements LlmEngine {
  @override
  Future<LlmResponse> generateContent(List<LlmMessage> messages, {LlmConfig? config}) async {
    try {
      // Stub for multi-modal / offline execution
    } catch (e) {
      debugPrint('[GemmaEngine] generateContent failed: $e');
    }
    return const LlmResponse(text: '');
  }

  @override
  Stream<String> generateTextStream(List<LlmMessage> messages, {LlmConfig? config}) async* {
    try {
      // flutter_gemma supports streaming
    } catch (e) {
      debugPrint('[GemmaEngine] generateTextStream failed: $e');
    }
    yield '';
  }
}
