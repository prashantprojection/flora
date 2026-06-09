import 'dart:convert';

import 'package:uuid/uuid.dart';

/// A persistence-safe representation of a single chat message in a
/// follow-up conversation. Unlike [LlmMessage], this model never holds
/// raw image bytes — only file paths — so it can be safely serialized
/// to Hive / JSON without bloating storage.
///
/// Conversion to/from [LlmMessage] happens at the session layer.
class PersistedChatMessage {
  /// Unique identifier for the message.
  final String id;

  /// 'user' or 'model'
  final String role;

  /// The text content of the message (may be plain text or a JSON GenUI payload).
  final String text;

  /// The timestamp when the message was created.
  final DateTime timestamp;

  /// A brief background summary of what happened in this conversational turn.
  final String? contextSummary;

  /// The GenUI tool name used for this message, if any (e.g. 'render_tip_card').
  /// Null for plain-text model responses and all user messages.
  final String? toolName;

  /// Absolute path of a user-attached image file.
  /// Null if no image was attached to this message.
  /// Never contains raw bytes — loaded lazily from disk when displayed.
  final String? imagePath;

  const PersistedChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.contextSummary,
    this.toolName,
    this.imagePath,
  });

  factory PersistedChatMessage.fromJson(Map<String, dynamic> json) {
    return PersistedChatMessage(
      id: json['id'] as String? ?? const Uuid().v4(), // Fallback for old data
      role: json['role'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(), // Fallback for old data
      contextSummary: json['contextSummary'] as String?,
      toolName: json['toolName'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      if (contextSummary != null) 'contextSummary': contextSummary,
      if (toolName != null) 'toolName': toolName,
      if (imagePath != null) 'imagePath': imagePath,
    };
  }

  // ── List serialization helpers ──────────────────────────────────────────────

  /// Serialize a list of messages to a compact JSON string for Hive storage.
  static String encodeList(List<PersistedChatMessage> messages) {
    return jsonEncode(messages.map((m) => m.toJson()).toList());
  }

  /// Deserialize from a Hive-stored JSON string.
  /// Returns empty list on any parse failure.
  static List<PersistedChatMessage> decodeList(String json) {
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((e) => PersistedChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
