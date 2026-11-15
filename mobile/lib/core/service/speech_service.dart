import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sightmate/features/speech/domains/speech_language.dart';

class SpeechService {
  SpeechService._internal();

  // Une instance partagée par toute l'application.
  static final SpeechService instance = SpeechService._internal();

  final FlutterTts _tts = FlutterTts();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _languageKey = 'sightmate_speech_language';

  static const String _rateKey = 'sightmate_speech_rate';

  Future<void>? _initialization;

  SpeechLanguage _language = SpeechLanguage.french;
  double _speechRate = 0.5;

  SpeechLanguage get language => _language;
  double get speechRate => _speechRate;

  Future<void> initialize() {
    return _initialization ??= _initializeInternal().catchError((
      Object error,
      StackTrace stack,
    ) {
      _initialization = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _initializeInternal() async {
    await _tts.awaitSpeakCompletion(true);

    final savedCode = await _prefs.getString(_languageKey);
    final requestedLanguage = SpeechLanguage.fromCode(savedCode);

    // Préférer la langue enregistrée.
    if (await isLanguageAvailable(requestedLanguage)) {
      _language = requestedLanguage;
    } else {
      // Essayer les autres langues supportées.
      bool found = false;

      for (final candidate in SpeechLanguage.values) {
        if (await isLanguageAvailable(candidate)) {
          _language = candidate;
          found = true;
          break;
        }
      }

      if (!found) {
        throw StateError('Aucune voix française ou anglaise disponible.');
      }
    }

    _speechRate = (await _prefs.getDouble(_rateKey) ?? 0.5)
        .clamp(0.25, 0.85)
        .toDouble();

    await _tts.setLanguage(_language.code);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<bool> isLanguageAvailable(SpeechLanguage language) async {
    final result = await _tts.isLanguageAvailable(language.code);
    return result == true;
  }

  Future<void> setLanguage(SpeechLanguage language) async {
    await initialize();

    if (_language == language) return;

    if (!await isLanguageAvailable(language)) {
      throw StateError('Langue indisponible : ${language.label}');
    }

    await _tts.stop();
    await _tts.setLanguage(language.code);

    _language = language;
    await _prefs.setString(_languageKey, language.code);
  }

  Future<void> setSpeechRate(double rate) async {
    await initialize();

    final safeRate = rate.clamp(0.25, 0.85).toDouble();

    await _tts.setSpeechRate(safeRate);
    _speechRate = safeRate;

    await _prefs.setDouble(_rateKey, safeRate);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await initialize();

    // Remplacer toute annonce en cours.
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // À réserver à l'arrêt définitif du service.
  Future<void> dispose() async {
    await _tts.stop();
  }
}
