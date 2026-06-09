import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';

class OpenAiEngine extends LlmEngine {
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAiEngine({String? apiKey, String? modelId})
    : super(
        apiKey: apiKey ?? '',
        modelId: modelId ?? 'gpt-4o-mini',
      );

  // ── Schema Mapper ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>>? _mapTools(List<LlmTool>? tools) {
    if (tools == null || tools.isEmpty) return null;
    return tools.map((t) {
      return {
        'type': 'function',
        'function': {
          'name': t.name,
          'description': t.description,
          'parameters': t
              .schema, // Our schema perfectly matches OpenAI's JSON Schema format
        },
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapMessages(List<LlmMessage> messages) {
    return messages.map((m) {
      final role = m.role == LlmRole.user ? 'user' : 'assistant';

      if (m.image != null) {
        final base64Image = base64Encode(m.image!);
        return {
          'role': role,
          'content': [
            {'type': 'text', 'text': m.text},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            },
          ],
        };
      }

      return {'role': role, 'content': m.text};
    }).toList();
  }

  // ── Public Interface ──────────────────────────────────────────────────────

  @override
  Future<LlmResponse> doGenerateContent(
    List<LlmMessage> messages, {
    LlmConfig? config,
  }) async {
    final mappedTools = _mapTools(config?.tools);
    final body = {
      'model': modelId,
      'messages': _mapMessages(messages),
      if (config?.temperature != null) 'temperature': config!.temperature,
      if (config?.maxTokens != null) 'max_tokens': config!.maxTokens,
      'tools': mappedTools,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API Error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final message = data['choices'][0]['message'];

    LlmFunctionCall? functionCall;
    if (message['tool_calls'] != null && message['tool_calls'].isNotEmpty) {
      final toolCall = message['tool_calls'][0]['function'];
      try {
        functionCall = LlmFunctionCall(
          name: toolCall['name'],
          arguments: jsonDecode(toolCall['arguments']),
        );
      } catch (e) {
        debugPrint('[OpenAiEngine] Failed to parse tool arguments: $e');
        functionCall = LlmFunctionCall(
          name: toolCall['name'],
          arguments: {}, // Graceful fallback
        );
      }
    }

    return LlmResponse(text: message['content'], functionCall: functionCall);
  }

  @override
  Stream<String> doGenerateTextStream(
    List<LlmMessage> messages, {
    LlmConfig? config,
  }) async* {
    final body = {
      'model': modelId,
      'messages': _mapMessages(messages),
      'stream': true,
      if (config?.temperature != null) 'temperature': config!.temperature,
      if (config?.maxTokens != null) 'max_tokens': config!.maxTokens,
    };

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    });
    request.body = jsonEncode(body);

    final response = await request.send().timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'OpenAI Stream Error ${response.statusCode}: $errorBody',
      );
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('data: ') && line != 'data: [DONE]') {
        final data = line.substring(6);
        final json = jsonDecode(data);
        if (json['choices'] != null && (json['choices'] as List).isNotEmpty) {
          final delta = json['choices'][0]['delta'];
          if (delta['content'] != null) {
            yield delta['content'] as String;
          }
        }
      }
    }
  }
}
