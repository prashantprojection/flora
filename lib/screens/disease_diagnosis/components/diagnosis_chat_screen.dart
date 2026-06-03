import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:flora/utils/app_theme.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/providers/diagnosis_session_provider.dart';
import 'package:flora/screens/disease_diagnosis/components/chat/follow_up_genui_renderer.dart';

/// Full-screen follow-up chat screen pushed via [Navigator.push] from
/// [DiagnosisResultView]. Back button returns to the result view with
/// all state preserved (same [diagnosisSessionProvider] instance).
///
/// Only shows follow-up messages (chatHistory index 2+).
/// Never re-sends the original plant image to the AI.
class DiagnosisChatScreen extends ConsumerStatefulWidget {
  const DiagnosisChatScreen({super.key});

  @override
  ConsumerState<DiagnosisChatScreen> createState() =>
      _DiagnosisChatScreenState();
}

class _DiagnosisChatScreenState extends ConsumerState<DiagnosisChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final state = ref.read(diagnosisSessionProvider);
    if (text.isEmpty || state.isLoading) return;

    _textController.clear();
    await ref.read(diagnosisSessionProvider.notifier).sendFollowUp(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _fillInput(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(diagnosisSessionProvider);
    final notifier = ref.read(diagnosisSessionProvider.notifier);
    final followUps = state.followUpHistory;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.foreground),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to diagnosis',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ask Dr. Flo',
              style: TextStyle(
                color: AppTheme.foreground,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (state.diagnosisResult != null)
              Text(
                state.diagnosisResult!.diseaseName,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: followUps.isEmpty && !state.isLoading
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: followUps.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == followUps.length) {
                        return _buildLoadingBubble(context, state.loadingMessage);
                      }

                      final message = followUps[index];
                      if (message.role == LlmRole.user) {
                        return _UserBubble(message: message);
                      } else {
                        return FollowUpGenUiRenderer(
                          message: message,
                          onSuggestionTap: _fillInput,
                        );
                      }
                    },
                  ),
          ),
          _ChatInputBar(
            controller: _textController,
            isLoading: state.isLoading,
            pendingAttachment: state.pendingAttachment,
            onPickAttachment: notifier.pickAttachment,
            onClearAttachment: notifier.clearAttachment,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.messageCircleQuestion,
              size: 48,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask Dr. Flo anything',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.foreground,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask follow-up questions about your plant\'s diagnosis, treatment, or care.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedForeground, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context, String? message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              message ?? 'Thinking...',
              style: const TextStyle(
                  color: AppTheme.mutedForeground, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User message bubble ────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final LlmMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat input bar ─────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final File? pendingAttachment;
  final VoidCallback onPickAttachment;
  final VoidCallback onClearAttachment;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.pendingAttachment,
    required this.onPickAttachment,
    required this.onClearAttachment,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border:
              Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingAttachment != null)
              Padding(
                padding:
                    const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        pendingAttachment!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image attached',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.mutedForeground),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: onClearAttachment,
                      color: AppTheme.mutedForeground,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.paperclip,
                      color: pendingAttachment != null
                          ? AppTheme.primary
                          : AppTheme.mutedForeground,
                      size: 20,
                    ),
                    onPressed: isLoading ? null : onPickAttachment,
                    tooltip: 'Attach another image',
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Ask Dr. Flo...',
                        hintStyle: TextStyle(
                          color:
                              AppTheme.mutedForeground.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.sendHorizontal),
                    color: AppTheme.primary,
                    onPressed: isLoading ? null : onSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
