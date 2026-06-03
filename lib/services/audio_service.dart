import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  return service;
});

/// A skeleton service for future Speech-To-Text (Voice Chat) integration.
/// Follows the architecture convention of isolating native SDKs (like speech_to_text).
class AudioService {
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> initialize() async {
    // TODO: Initialize speech_to_text instance and request permissions
    _isInitialized = true;
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (!initResult) return;
    }
    
    _isListening = true;
    // TODO: Call speech_to_text listen() with SpeechListenOptions(listenMode: ListenMode.dictation, partialResults: true)
    
    // Simulating a callback for architecture purposes
    // onResult("This is a skeleton voice implementation", true);
  }

  Future<void> stopListening() async {
    _isListening = false;
    // TODO: Call speech_to_text stop()
  }
}
