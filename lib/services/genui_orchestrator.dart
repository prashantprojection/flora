
import 'package:flora/api/llm/llm_engine.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiToolResult {
  final LlmFunctionCall? functionCall;
  final String? text;

  AiToolResult({this.functionCall, this.text});

  bool get isWidget => functionCall != null;
}

class AiToolOrchestrator {
  final LlmEngine _engine;

  AiToolOrchestrator(this._engine);

  // ── Tool Catalog ──────────────────────────────────────────────────────────
  // All tools available to the AI for rendering rich, interactive UI.
  // Add new tools here — they are automatically available in all chat calls.

  static final _tools = [
    // ── Initial diagnosis result card ────────────────────────────────────────
    const LlmTool(
      name: 'render_diagnosis_card',
      description:
          'Renders a structured, visually appealing diagnosis card for a plant disease or health assessment.',
      schema: {
        'type': 'object',
        'properties': {
          'diseaseName': {
            'type': 'string',
            'description': 'The name of the detected disease or health condition.',
          },
          'severity': {
            'type': 'string',
            'description': 'Severity level: none, low, medium, or high.',
          },
          'symptoms': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of visible symptoms observed.',
          },
          'causes': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of potential causes.',
          },
          'treatment': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Ordered list of treatment steps.',
          },
          'prevention': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'List of prevention methods.',
          },
          'additionalNotes': {
            'type': 'string',
            'description': 'Any additional helpful notes.',
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

    // ── Single actionable tip ─────────────────────────────────────────────────
    const LlmTool(
      name: 'render_tip_card',
      description:
          'Renders a single focused, actionable tip or advice. Use for short, direct answers to follow-up questions.',
      schema: {
        'type': 'object',
        'properties': {
          'icon': {
            'type': 'string',
            'description':
                'Emoji or icon name representing the tip category (e.g. "💧" for watering, "☀️" for light).',
          },
          'title': {
            'type': 'string',
            'description': 'Short title for the tip (max 6 words).',
          },
          'body': {
            'type': 'string',
            'description': 'The full tip content (1-3 sentences).',
          },
          'urgency': {
            'type': 'string',
            'description': 'Urgency level: low, medium, or high.',
          },
        },
        'required': ['icon', 'title', 'body'],
      },
    ),

    // ── Step-by-step checklist ────────────────────────────────────────────────
    const LlmTool(
      name: 'render_care_checklist',
      description:
          'Renders an interactive checklist of care steps the user can tick off. Use when the user asks for a step-by-step plan.',
      schema: {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title of the checklist.',
          },
          'steps': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Ordered list of actionable steps.',
          },
        },
        'required': ['title', 'steps'],
      },
    ),

    // ── Short answer with follow-up suggestion chips ──────────────────────────
    const LlmTool(
      name: 'render_quick_answers',
      description:
          'Renders a brief answer with 2-4 tappable follow-up suggestion chips. Use for conversational exchanges where the user might want to dig deeper.',
      schema: {
        'type': 'object',
        'properties': {
          'answer': {
            'type': 'string',
            'description': 'The concise answer (1-2 sentences max).',
          },
          'suggestions': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                '2-4 short follow-up questions the user might want to ask next.',
          },
        },
        'required': ['answer', 'suggestions'],
      },
    ),

    // ── Revised severity indicator ────────────────────────────────────────────
    const LlmTool(
      name: 'render_severity_update',
      description:
          'Renders an updated severity assessment if the user describes new symptoms or worsening conditions.',
      schema: {
        'type': 'object',
        'properties': {
          'previousSeverity': {
            'type': 'string',
            'description': 'The original severity from the diagnosis.',
          },
          'updatedSeverity': {
            'type': 'string',
            'description': 'The revised severity: none, low, medium, or high.',
          },
          'reason': {
            'type': 'string',
            'description': 'Brief explanation of why the severity changed.',
          },
          'urgentAction': {
            'type': 'string',
            'description':
                'The single most important action the user should take right now.',
          },
        },
        'required': ['previousSeverity', 'updatedSeverity', 'reason', 'urgentAction'],
      },
    ),

    // ── Product / treatment suggestion ───────────────────────────────────────
    const LlmTool(
      name: 'render_product_suggestion',
      description:
          'Renders a recommendation for a product type or treatment approach (fungicide, neem oil, etc.). Do NOT recommend specific brands.',
      schema: {
        'type': 'object',
        'properties': {
          'productType': {
            'type': 'string',
            'description':
                'Category of product (e.g. "Copper-based fungicide", "Neem oil spray").',
          },
          'howToUse': {
            'type': 'string',
            'description': 'Brief application instructions.',
          },
          'frequency': {
            'type': 'string',
            'description':
                'How often to apply (e.g. "Every 7 days for 3 weeks").',
          },
          'caution': {
            'type': 'string',
            'description': 'Any safety note or when NOT to apply.',
          },
        },
        'required': ['productType', 'howToUse', 'frequency'],
      },
    ),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Initial diagnosis call — sends image + first user message.
  /// Called only once per session. No image stripping needed.
  Future<AiToolResult> executeToolChat(List<LlmMessage> messages) async {
    final config = LlmConfig(tools: _tools);
    final response = await _engine.generateContent(messages, config: config);

    return AiToolResult(
      functionCall: response.functionCall,
      text: response.text,
    );
  }

  /// Follow-up chat call — strips image bytes from all messages except index 0.
  /// This prevents re-uploading the original diagnosis photo on every turn.
  /// A new user-attached image (at the last message) is sent as-is.
  Future<AiToolResult> executeFollowUpChat(List<LlmMessage> messages) async {
    final config = LlmConfig(tools: _tools);

    // Strip image bytes from all history messages except index 0 (original)
    // and the last message (new user-attached image if present)
    final stripped = _stripImageBytes(messages);

    final response = await _engine.generateContent(stripped, config: config);

    return AiToolResult(
      functionCall: response.functionCall,
      text: response.text,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns a new list where image bytes are nulled out for all messages
  /// except index 0 (original diagnosis image) and the last message
  /// (which may carry a new user-attached image for a follow-up).
  List<LlmMessage> _stripImageBytes(List<LlmMessage> messages) {
    if (messages.length <= 1) return messages;

    return [
      for (int i = 0; i < messages.length; i++)
        // Keep bytes only for the first message and the last message
        if (i == 0 || i == messages.length - 1)
          messages[i]
        else if (messages[i].image != null)
          LlmMessage(role: messages[i].role, text: messages[i].text)
        else
          messages[i],
    ];
  }
}

final aiToolOrchestratorProvider = Provider<AiToolOrchestrator>((ref) {
  final engine = ref.watch(llmEngineProvider);
  return AiToolOrchestrator(engine);
});
