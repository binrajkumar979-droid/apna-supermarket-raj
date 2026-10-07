import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => debugPrint('Voice error: $val'),
        onStatus: (val) => debugPrint('Voice status: $val'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      return false;
    }
  }

  void startListening({
    required Function(String recognizedText) onResult,
    String localeId = 'hi_IN', // Defaults to Hindi for Indian Kirana shoppers
  }) async {
    final available = await initSpeech();
    if (available) {
      _speech.listen(
        localeId: localeId,
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            onResult(val.recognizedWords);
          }
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
