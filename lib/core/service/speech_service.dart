import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Attendre la fin de la lecture avant de terminer speak().
    await _tts.awaitSpeakCompletion(true);

    // Configuration initiale du moteur vocal.
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    if (!_initialized) {
      await initialize();
    }

    // Évite la superposition de messages vocaux.
    await _tts.stop();

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setSpeechRate(double rate) async {
    if (!_initialized) {
      await initialize();
    }

    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  Future<bool> isFrenchAvailable() async {
    // Vérifie la disponibilité de la langue sur Android.
    final result = await _tts.isLanguageAvailable('fr-FR');
    return result == true;
  }

  Future<void> dispose() async {
    await _tts.stop();
    _initialized = false;
  }
}
