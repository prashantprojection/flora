import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:flora/models/llm_models.dart';
import 'package:flora/models/diagnosis_data.dart';
import 'package:flora/models/diagnosis_record.dart';
import 'package:flora/models/chat_message.dart';
import 'package:flora/services/image_service.dart';
import 'package:flora/services/ai_service.dart';
import 'package:flora/services/tts_service.dart';
import 'package:flora/services/plant_classifier_service.dart';
import 'package:flora/utils/network_utils.dart';
import 'package:flora/providers/diagnosis_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class DiagnosisSessionState {
  final File? selectedImage;

  /// Full chat history.
  /// Index 0: initial user message (with image bytes — only for the API call).
  /// Index 1: AI diagnosis response (JSON string for GenUI card).
  /// Index 2+: follow-up user/model pairs.
  final List<LlmMessage> chatHistory;

  final bool isLoading;
  final String? loadingMessage;
  final String? currentRecordId;
  final bool isSpeaking;
  final String? error;
  final String? description;

  /// The parsed GenUI result from the initial diagnosis.
  /// Non-null means the diagnosis is complete and DiagnosisResultView should show.
  final DiagnosisData? diagnosisResult;

  /// An image the user has picked to attach to their NEXT follow-up message.
  /// Stored as a File reference — bytes are only read at send time.
  /// Cleared immediately after the message is sent.
  final File? pendingAttachment;

  const DiagnosisSessionState({
    this.selectedImage,
    this.chatHistory = const [],
    this.isLoading = false,
    this.loadingMessage,
    this.currentRecordId,
    this.isSpeaking = false,
    this.error,
    this.description,
    this.diagnosisResult,
    this.pendingAttachment,
  });

  DiagnosisSessionState copyWith({
    File? selectedImage,
    bool clearSelectedImage = false,
    List<LlmMessage>? chatHistory,
    bool? isLoading,
    String? loadingMessage,
    bool clearLoadingMessage = false,
    String? currentRecordId,
    bool clearCurrentRecordId = false,
    bool? isSpeaking,
    String? error,
    bool clearError = false,
    String? description,
    bool clearDescription = false,
    DiagnosisData? diagnosisResult,
    bool clearDiagnosisResult = false,
    File? pendingAttachment,
    bool clearPendingAttachment = false,
  }) {
    return DiagnosisSessionState(
      selectedImage:
          clearSelectedImage ? null : (selectedImage ?? this.selectedImage),
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage:
          clearLoadingMessage ? null : (loadingMessage ?? this.loadingMessage),
      currentRecordId: clearCurrentRecordId
          ? null
          : (currentRecordId ?? this.currentRecordId),
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: clearError ? null : (error ?? this.error),
      description:
          clearDescription ? null : (description ?? this.description),
      diagnosisResult: clearDiagnosisResult
          ? null
          : (diagnosisResult ?? this.diagnosisResult),
      pendingAttachment: clearPendingAttachment
          ? null
          : (pendingAttachment ?? this.pendingAttachment),
    );
  }

  /// Follow-up messages only (skips the initial diagnosis pair at indices 0–1).
  List<LlmMessage> get followUpHistory =>
      chatHistory.length > 2 ? chatHistory.sublist(2) : [];

  /// Whether a follow-up conversation has been started.
  bool get hasFollowUps => followUpHistory.isNotEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class DiagnosisSessionNotifier extends Notifier<DiagnosisSessionState> {
  static const int _maxFollowUpPairs = 50; // 100 messages max after initial 2

  final PlantClassifierService _classifierService = PlantClassifierService();

  @override
  DiagnosisSessionState build() => const DiagnosisSessionState();

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> pickImage(bool fromCamera) async {
    await ref.read(ttsServiceProvider).stop();
    state = state.copyWith(isSpeaking: false, clearError: true);

    try {
      final File? pickedFile =
          await ImageService.pickImage(fromCamera: fromCamera);
      if (pickedFile != null) {
        state = state.copyWith(
          selectedImage: File(pickedFile.path),
          chatHistory: [],
          clearCurrentRecordId: true,
          clearDescription: true,
          clearDiagnosisResult: true,
          clearPendingAttachment: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Error picking image: $e');
    }
  }

  /// Pick an additional image to attach to the next follow-up message.
  /// Does NOT reset the diagnosis session.
  Future<void> pickAttachment() async {
    try {
      final File? pickedFile =
          await ImageService.pickImage(fromCamera: false);
      if (pickedFile != null) {
        state = state.copyWith(pendingAttachment: File(pickedFile.path));
      }
    } catch (e) {
      state = state.copyWith(error: 'Error picking image: $e');
    }
  }

  void clearAttachment() {
    state = state.copyWith(clearPendingAttachment: true);
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);
  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  void resetState() {
    ref.read(ttsServiceProvider).stop();
    state = const DiagnosisSessionState();
  }

  // ── View history record ────────────────────────────────────────────────────

  /// Restores a session from a persisted [DiagnosisRecord].
  /// DiagnosisData is reconstructed synchronously (fast JSON parse).
  /// Chat history (if any) is loaded off the main thread via [compute].
  Future<void> viewRecord(DiagnosisRecord record) async {
    // Synchronous — show result immediately
    final diagnosisData = DiagnosisData.fromString(record.diagnosis);
    final imageFile = File(record.imagePath).existsSync()
        ? File(record.imagePath)
        : null;

    state = state.copyWith(
      selectedImage: imageFile,
      diagnosisResult:
          diagnosisData.diseaseName != 'Error' ? diagnosisData : null,
      currentRecordId: record.id,
      clearDescription: true,
      clearError: true,
      isSpeaking: false,
      clearPendingAttachment: true,
      // Set an initial history so the result view has something to work with
      chatHistory: [
        LlmMessage(
          role: LlmRole.user,
          text: 'Plant image analysis from ${record.date.toString().substring(0, 10)}',
        ),
        LlmMessage(role: LlmRole.model, text: record.diagnosis),
      ],
    );

    // Async — load follow-up chat history off the main thread if it exists
    if (record.chatMessages != null && record.chatMessages!.isNotEmpty) {
      final persisted = await compute(
        _parseChatMessages,
        record.chatMessages!,
      );
      final followUps = persisted.map((m) => LlmMessage(
            role: m.role == 'user' ? LlmRole.user : LlmRole.model,
            text: m.text,
            contextSummary: m.contextSummary,
            // imagePath will be loaded lazily in the UI — we don't load bytes here
          )).toList();

      // Append to the synthetic history we set above
      state = state.copyWith(
        chatHistory: [...state.chatHistory, ...followUps],
      );
    }
  }

  // ── Initial diagnosis ──────────────────────────────────────────────────────

  Future<void> runDiagnosis() async {
    if (state.selectedImage == null) return;

    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Checking connection...',
      clearError: true,
    );

    if (!await _verifyNetworkConnection()) return;
    if (!await _validatePlantImage()) return;
    await _fetchAiDiagnosis();
  }

  Future<bool> _verifyNetworkConnection() async {
    final hasInternet = await NetworkUtils.hasInternetConnection();
    if (!hasInternet) {
      state = state.copyWith(
        isLoading: false,
        error: 'No internet. Diagnosis requires online access.',
      );
      return false;
    }
    return true;
  }

  Future<bool> _validatePlantImage() async {
    state = state.copyWith(loadingMessage: 'Analyzing plant...');
    try {
      final isPlant =
          await _classifierService.isPlant(state.selectedImage!.path);
      if (!isPlant) {
        state = state.copyWith(
          isLoading: false,
          error:
              'No plant detected. Please ensure the image clearly shows a plant leaf.',
        );
        return false;
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not verify plant image. Please try again.',
      );
      return false;
    }
  }

  Future<void> _fetchAiDiagnosis() async {
    state = state.copyWith(loadingMessage: 'Diagnosing with AI...');
    final aiService = ref.read(aiServiceProvider);

    try {
      // Read bytes, send to API — bytes are NOT stored in state
      final imageBytes = await state.selectedImage!.readAsBytes();
      final desc = state.description;

      final userMessage = LlmMessage(
        role: LlmRole.user,
        text: desc != null && desc.isNotEmpty
            ? 'Here is a plant photo. Additional note: $desc'
            : 'Here is a plant photo.',
        image: imageBytes,
      );

      state = state.copyWith(chatHistory: [userMessage]);

      final aiResponse =
          await aiService.processDiseaseDiagnosisChat(state.chatHistory);

      // Parse the GenUI JSON into DiagnosisData — stored in state (no bytes)
      final diagnosisData = DiagnosisData.fromString(aiResponse);
      final hasValidResult = diagnosisData.diseaseName != 'Error';

      final aiMessage = LlmMessage(role: LlmRole.model, text: aiResponse);

      state = state.copyWith(
        chatHistory: [...state.chatHistory, aiMessage],
        diagnosisResult: hasValidResult ? diagnosisData : null,
        isLoading: false,
        clearLoadingMessage: true,
      );

      // After state is updated, clear image bytes from the stored message
      // by replacing it with a text-only version (bytes already sent to API)
      final historyWithoutBytes = [
        LlmMessage(role: LlmRole.user, text: state.chatHistory[0].text),
        ...state.chatHistory.sublist(1),
      ];
      state = state.copyWith(chatHistory: historyWithoutBytes);

      await _saveToHistory(aiResponse);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearLoadingMessage: true,
        error: 'Diagnosis failed. Please try again.',
      );
    }
  }

  Future<void> _saveToHistory(String aiResponse) async {
    final recordId = const Uuid().v4();
    final record = DiagnosisRecord(
      id: recordId,
      imagePath: state.selectedImage!.path,
      diagnosis: aiResponse,
      date: DateTime.now(),
    );

    await ref.read(diagnosisHistoryProvider.notifier).addDiagnosis(record);
    state = state.copyWith(currentRecordId: recordId);
  }

  // ── Follow-up chat ─────────────────────────────────────────────────────────

  /// Sends a follow-up message. Optionally includes a new image attachment.
  /// Image bytes are read just before the API call and freed immediately after.
  /// Chat is auto-saved to Hive after every successful response (non-blocking).
  Future<void> sendFollowUp(String text) async {
    if (text.isEmpty) return;

    // Enforce max history to keep memory bounded
    _trimHistoryIfNeeded();

    state = state.copyWith(
      isLoading: true,
      loadingMessage: 'Thinking...',
      clearError: true,
    );

    if (!await _verifyNetworkConnection()) return;

    // Read attachment bytes if present
    Uint8List? attachmentBytes;
    final attachment = state.pendingAttachment;
    if (attachment != null) {
      try {
        attachmentBytes = await attachment.readAsBytes();
      } catch (_) {
        attachmentBytes = null;
      }
    }

    final userMessage = LlmMessage(
      role: LlmRole.user,
      text: text,
      image: attachmentBytes, // may be null
    );

    state = state.copyWith(
      chatHistory: [...state.chatHistory, userMessage],
      clearPendingAttachment: true, // clear from state immediately
    );

    try {
      final aiService = ref.read(aiServiceProvider);
      final aiResult =
          await aiService.processFollowUpChat(state.chatHistory);

      // Free the attachment bytes from the sent message
      // (replace with a no-bytes version that keeps the imagePath for UI display)
      final historyWithoutBytes = [
        ...state.chatHistory.sublist(0, state.chatHistory.length - 1),
        LlmMessage(
          role: LlmRole.user,
          text: text,
          contextSummary: text, // The user's prompt serves as its own summary
        ),
      ];

      final aiMessage = LlmMessage(
        role: LlmRole.model, 
        text: aiResult.isWidget ? jsonEncode(aiResult.functionCall!.arguments) : (aiResult.text ?? ''),
        contextSummary: aiResult.text, // The LLM's plain text serves as its summary
      );
      state = state.copyWith(
        chatHistory: [...historyWithoutBytes, aiMessage],
        isLoading: false,
        clearLoadingMessage: true,
      );

      // Auto-save follow-up chat to Hive — non-blocking, UI never waits
      _autoSaveChatAsync(attachment?.path);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearLoadingMessage: true,
        error: 'Failed to get response. Please try again.',
      );
    }
  }

  /// Trims oldest follow-up pair if history exceeds the cap.
  void _trimHistoryIfNeeded() {
    final followUps = state.followUpHistory;
    if (followUps.length >= _maxFollowUpPairs * 2) {
      // Remove oldest 10 follow-up messages (5 pairs) to make room
      final trimmed = [
        ...state.chatHistory.sublist(0, 2), // keep initial diagnosis pair
        ...state.chatHistory.sublist(12),   // skip oldest 5 follow-up pairs
      ];
      state = state.copyWith(chatHistory: trimmed);
    }
  }

  /// Saves follow-up messages to the Hive record asynchronously.
  /// Called after every successful follow-up response.
  void _autoSaveChatAsync(String? lastAttachmentPath) {
    final recordId = state.currentRecordId;
    if (recordId == null) return;

    final followUps = state.followUpHistory;
    if (followUps.isEmpty) return;

    // Build persisted representation — no bytes, only file paths
    final persisted = <PersistedChatMessage>[];
    for (int i = 0; i < followUps.length; i++) {
      final msg = followUps[i];
      // For the last user message, attach the image path if one was sent
      final isLastUserMsg =
          i == followUps.length - 2 && msg.role == LlmRole.user;
      persisted.add(PersistedChatMessage(
        id: const Uuid().v4(),
        role: msg.role == LlmRole.user ? 'user' : 'model',
        text: msg.text,
        timestamp: DateTime.now(),
        contextSummary: msg.contextSummary,
        imagePath: isLastUserMsg ? lastAttachmentPath : null,
      ));
    }

    final chatJson = PersistedChatMessage.encodeList(persisted);

    // Fire and forget — no await, no UI block
    ref
        .read(diagnosisHistoryProvider.notifier)
        .updateChatMessages(recordId, chatJson);
  }

  // ── TTS ───────────────────────────────────────────────────────────────────

  Future<void> speakDiagnosis() async {
    if (state.chatHistory.isEmpty) return;
    final ttsService = ref.read(ttsServiceProvider);

    if (state.isSpeaking) {
      await ttsService.stop();
      state = state.copyWith(isSpeaking: false);
    } else {
      state = state.copyWith(isSpeaking: true);
      await ttsService.stop();

      await ttsService.init((isSpeaking) {
        // Guard against state updates after reset
        if (state.currentRecordId != null || state.diagnosisResult != null) {
          state = state.copyWith(isSpeaking: isSpeaking);
        }
      });

      final lastMsg = state.chatHistory.lastWhere(
        (m) => m.role == LlmRole.model,
        orElse: () => const LlmMessage(role: LlmRole.model, text: ''),
      );

      final cleanText = lastMsg.text
          .replaceAll('**', '')
          .replaceAll('#', '')
          .replaceAll('*', '');

      await ttsService.speak(cleanText);
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  void provideFeedback(bool isHelpful) {
    if (state.currentRecordId != null) {
      ref
          .read(diagnosisHistoryProvider.notifier)
          .updateDiagnosisFeedback(state.currentRecordId!, isHelpful);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final diagnosisSessionProvider =
    NotifierProvider<DiagnosisSessionNotifier, DiagnosisSessionState>(() {
  return DiagnosisSessionNotifier();
});

// ── Isolate helper (top-level for compute) ────────────────────────────────────

List<PersistedChatMessage> _parseChatMessages(String json) {
  return PersistedChatMessage.decodeList(json);
}
