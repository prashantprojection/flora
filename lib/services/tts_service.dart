import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _handlersSet = false;

  Future<void> init(Function(bool) onSpeakingStateChanged) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Only register handlers once; calling setStartHandler again on the same
    // FlutterTts instance just overwrites the previous closure — no leak, but
    // we skip the call to avoid unnecessary overhead on repeat init calls.
    if (!_handlersSet) {
      _flutterTts.setStartHandler(() {
        onSpeakingStateChanged(true);
      });

      _flutterTts.setCompletionHandler(() {
        onSpeakingStateChanged(false);
      });

      _flutterTts.setErrorHandler((msg) {
        onSpeakingStateChanged(false);
      });

      _handlersSet = true;
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Releases the underlying FlutterTts engine. Called automatically by the
  /// Riverpod provider when the ProviderScope is disposed.
  Future<void> dispose() async {
    await _flutterTts.stop();
    await _flutterTts.awaitSpeakCompletion(false);
  }
}
