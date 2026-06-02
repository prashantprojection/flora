import 'package:flutter/foundation.dart';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';

class GemmaEngine implements LlmEngine {
  @override
  Future<LlmResponse> generateResponse(String prompt, {LlmConfig? config}) async {
    try {
      // Stub
    } catch (e) {
      debugPrint('[GemmaEngine] generateResponse failed: $e');
    }
    return const LlmResponse(text: '');
  }

  @override
  Stream<String> generateTextStream(String prompt, {LlmConfig? config}) async* {
    try {
      // flutter_gemma supports streaming via:
      // final model = await FlutterGemma.getActiveModel(maxTokens: config?.maxTokens ?? 2048);
      // final chat = await model.createChat();
      // await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      // await for (final chunk in chat.generateChatResponseStream()) {
      //   yield chunk ?? '';
      // }
    } catch (e) {
      debugPrint('[GemmaEngine] generateTextStream failed: $e');
    }

    // Fallback stub: instantly yield the full response for testing UI
    yield '';
  }

  @override
  Future<LlmResponse> generateChat(List<LlmMessage> messages, {LlmConfig? config}) async {
    try {
      // Stub
    } catch (e) {
      debugPrint('[GemmaEngine] generateChat failed: $e');
    }
    return const LlmResponse(text: '');
  }

  @override
  Future<LlmResponse> generateResponseFromImage(String prompt, Uint8List image, {LlmConfig? config}) async {
    try {
      // Offline multi-modal stub
    } catch (e) {
      debugPrint('[GemmaEngine] generateResponseFromImage failed: $e');
    }
    return const LlmResponse(text: '');
  }
}
