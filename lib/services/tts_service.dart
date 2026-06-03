import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> init(Function(bool) onSpeakingStateChanged) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      onSpeakingStateChanged(true);
    });
    
    _flutterTts.setCompletionHandler(() {
      onSpeakingStateChanged(false);
    });

    _flutterTts.setErrorHandler((msg) {
      onSpeakingStateChanged(false);
    });
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
