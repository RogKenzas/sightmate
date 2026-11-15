import 'speech_language.dart';

class SpeechMessages {
  SpeechMessages._();

  static String photoCaptured(SpeechLanguage language) {
    switch (language) {
      case SpeechLanguage.french:
        return 'Photo capturée';

      case SpeechLanguage.english:
        return 'Photo captured';
    }
  }

  static String cameraUnavailable(SpeechLanguage language) {
    switch (language) {
      case SpeechLanguage.french:
        return 'La caméra est indisponible.';

      case SpeechLanguage.english:
        return 'The camera is unavailable.';
    }
  }

  static String captureFailed(SpeechLanguage language) {
    switch (language) {
      case SpeechLanguage.french:
        return 'Impossible de prendre la photo.';

      case SpeechLanguage.english:
        return 'Unable to take the picture.';
    }
  }
}
