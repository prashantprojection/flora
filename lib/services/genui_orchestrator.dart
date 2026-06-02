import 'dart:typed_data';
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenUiResult {
  final LlmFunctionCall? functionCall;
  final String? text;

  GenUiResult({this.functionCall, this.text});

  bool get isWidget => functionCall != null;
}

class GenUiOrchestrator {
  final LlmEngine _engine;

  GenUiOrchestrator(this._engine);

  static final _tools = [
    const LlmTool(
      name: 'render_diagnosis_card',
      description: 'Renders a structured, visually appealing diagnosis card for a plant disease.',
      schema: {
        'type': 'object',
        'properties': {
          'diseaseName': {
            'type': 'string',
            'description': 'The name of the detected plant disease or condition.',
          },
          'severity': {
            'type': 'string',
            'description': 'Severity level: low, medium, or high.',
          },
          'symptoms': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of visible symptoms.',
          },
          'causes': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of potential causes.',
          },
          'treatment': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of treatment steps.',
          },
          'prevention': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of prevention methods.',
          },
          'additionalNotes': {
            'type': 'string',
            'description': 'Any other helpful notes for the user.',
          },
        },
        'required': [
          'diseaseName',
          'severity',
          'symptoms',
          'causes',
          'treatment',
          'prevention',
        ],
      },
    ),
  ];

  Future<GenUiResult> generateGenUi(String prompt, {List<LlmMessage>? history}) async {
    final config = LlmConfig(tools: _tools);

    LlmResponse response;
    if (history != null && history.isNotEmpty) {
      // Chat mode
      final messages = List<LlmMessage>.from(history)..add(LlmMessage(role: LlmRole.user, text: prompt));
      response = await _engine.generateChat(messages, config: config);
    } else {
      // Single prompt mode
      response = await _engine.generateResponse(prompt, config: config);
    }

    if (response.isFunctionCall) {
      return GenUiResult(functionCall: response.functionCall);
    }

    return GenUiResult(text: response.text);
  }

  Future<GenUiResult> generateGenUiFromImage(String prompt, Uint8List image) async {
    final config = LlmConfig(tools: _tools);
    final response = await _engine.generateResponseFromImage(prompt, image, config: config);
    
    if (response.isFunctionCall) {
      return GenUiResult(functionCall: response.functionCall);
    }
    return GenUiResult(text: response.text);
  }
}

final genUiOrchestratorProvider = Provider<GenUiOrchestrator>((ref) {
  final engine = ref.watch(llmEngineProvider);
  return GenUiOrchestrator(engine);
});
