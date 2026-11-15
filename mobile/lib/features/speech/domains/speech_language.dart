enum SpeechLanguage {
  french('fr-FR', 'Français'),
  english('en-US', 'English');

  const SpeechLanguage(this.code, this.label);

  final String code;
  final String label;

  String get sampleMessage {
    switch (this) {
      case SpeechLanguage.french:
        return 'Bonjour, bienvenue sur SightMate. '
            'Votre assistant visuel est prêt '
            'à vous accompagner.';

      case SpeechLanguage.english:
        return 'Hello, welcome to SightMate. '
            'Your visual assistant is ready to help you.';
    }
  }

  static SpeechLanguage fromCode(String? code) {
    for (final language in SpeechLanguage.values) {
      if (language.code == code) return language;
    }
    return SpeechLanguage.french;
  }
}
