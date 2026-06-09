import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';

class AnthropicEngine extends LlmEngine {
  final String _baseUrl = 'https://api.anthropic.com/v1/messages';
  final String _apiVersion = '2023-06-01';

  AnthropicEngine({String? apiKey, String? modelId})
    : super(
        apiKey: apiKey ?? '',
        modelId: modelId ?? 'claude-3-haiku-20240307',
      );

  // ── Schema Mapper ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>>? _mapTools(List<LlmTool>? tools) {
    if (tools == null || tools.isEmpty) return null;
    return tools.map((t) {
      return {
        'name': t.name,
        'description': t.description,
        'input_schema': t
            .schema, // Our schema perfectly matches Anthropic's JSON Schema format
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
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {'type': 'text', 'text': m.text},
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
        'max_tokens': config?.maxTokens ?? 1024,
        if (config?.temperature != null) 'temperature': config!.temperature,
        'tools': mappedTools,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': _apiVersion,
          'Content-Type': 'application/json',
          'anthropic-dangerous-direct-browser-access':
              'true', // Required for client-side CORS issues if applicable, harmless on mobile
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Anthropic API Error ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body);

      String? text;
      LlmFunctionCall? functionCall;

      for (var content in data['content']) {
        if (content['type'] == 'text') {
          text = content['text'];
        } else if (content['type'] == 'tool_use') {
          functionCall = LlmFunctionCall(
            name: content['name'],
            arguments: content['input'],
          );
        }
      }

      return LlmResponse(text: text, functionCall: functionCall);
  }

  @override
  Stream<String> doGenerateTextStream(
    List<LlmMessage> messages, {
    LlmConfig? config,
  }) async* {
    final body = {
      'model': modelId,
        'messages': _mapMessages(messages),
        'max_tokens': config?.maxTokens ?? 1024,
        'stream': true,
        if (config?.temperature != null) 'temperature': config!.temperature,
      };

      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
        'Content-Type': 'application/json',
        'anthropic-dangerous-direct-browser-access': 'true',
      });
      request.body = jsonEncode(body);

      final response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
          'Anthropic Stream Error ${response.statusCode}: $errorBody',
        );
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.startsWith('data: ') && line != 'data: [DONE]') {
          final data = line.substring(6);
          final json = jsonDecode(data);

          if (json['type'] == 'content_block_delta' &&
              json['delta'] != null &&
              json['delta']['type'] == 'text_delta') {
            yield json['delta']['text'] as String;
          }
        }
      }
  }
}
