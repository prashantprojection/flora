import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:flora/models/llm_models.dart';
import 'package:flora/widgets/genui/tip_card.dart';
import 'package:flora/widgets/genui/care_checklist.dart';
import 'package:flora/widgets/genui/quick_answers_card.dart';
import 'package:flora/widgets/genui/severity_update_card.dart';
import 'package:flora/widgets/genui/product_suggestion_card.dart';
import 'package:flora/screens/disease_diagnosis/components/chat/chat_genui_card.dart';

/// Dispatches an AI follow-up response to the correct interactive GenUI widget.
///
/// Parses the message text — if it's a JSON tool response, routes to the
/// matching named widget. Falls back to [MarkdownBody] for plain text.
class FollowUpGenUiRenderer extends StatelessWidget {
  final LlmMessage message;

  /// Called when the user taps a suggestion chip — pre-fills the chat input.
  final ValueChanged<String>? onSuggestionTap;

  const FollowUpGenUiRenderer({
    super.key,
    required this.message,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message.text.trim();

    // Detect GenUI JSON by leading brace
    if (text.startsWith('{')) {
      try {
        final Map<String, dynamic> json = jsonDecode(text);

        if (json.containsKey('diseaseName')) {
          return ChatGenUiCard(message: message);
        }
        if (json.containsKey('icon') &&
            json.containsKey('title') &&
            json.containsKey('body')) {
          return TipCard(data: json);
        }
        if (json.containsKey('steps')) {
          return CareChecklist(data: json);
        }
        if (json.containsKey('suggestions')) {
          return QuickAnswersCard(
              data: json, onSuggestionTap: onSuggestionTap);
        }
        if (json.containsKey('updatedSeverity')) {
          return SeverityUpdateCard(data: json);
        }
        if (json.containsKey('productType')) {
          return ProductSuggestionCard(data: json);
        }
      } catch (_) {
        // Not valid JSON — fall through to Markdown
      }
    }

    // Plain text / Markdown fallback
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
