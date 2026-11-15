import 'package:material_ui/material_ui.dart';
import 'package:sightmate/core/service/speech_service.dart';
import 'package:sightmate/features/speech/domains/speech_language.dart';

class SpeechTestScreen extends StatefulWidget {
  const SpeechTestScreen({super.key});

  @override
  State<SpeechTestScreen> createState() => _SpeechTestScreenState();
}

class _SpeechTestScreenState extends State<SpeechTestScreen> {
  final SpeechService _speechService = SpeechService.instance;

  SpeechLanguage _language = SpeechLanguage.french;

  double _speechRate = 0.5;
  bool _ready = false;
  bool _busy = false;
  bool _speaking = false;

  // Permet d'ignorer les fins de lecture obsolètes.
  int _playbackVersion = 0;

  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _speechService.initialize();

      if (!mounted) return;
      setState(() {
        _language = _speechService.language;
        _speechRate = _speechService.speechRate;
        _ready = true;
      });
    } catch (e) {
      debugPrint('SightMate TTS init error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Impossible d’initialiser la voix.';
      });
    }
  }

  Future<void> _changeLanguage(SpeechLanguage language) async {
    if (!_ready || _busy || language == _language) {
      return;
    }

    ++_playbackVersion;

    setState(() {
      _busy = true;
      _speaking = false;
      _error = null;
    });

    try {
      await _speechService.setLanguage(language);

      if (!mounted) return;

      setState(() {
        _language = language;
      });
    } catch (e) {
      debugPrint('SightMate language error: $e');

      if (!mounted) return;

      setState(() {
        _error = 'La voix sélectionnée est indisponible.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _speak() async {
    if (!_ready || _busy || _speaking) return;

    final version = ++_playbackVersion;

    setState(() {
      _speaking = true;
      _error = null;
    });

    try {
      await _speechService.speak(_language.sampleMessage);
    } catch (e) {
      debugPrint('SightMate speech error: $e');

      if (mounted && version == _playbackVersion) {
        setState(() {
          _error = 'Impossible de lire le message.';
        });
      }
    } finally {
      if (mounted && version == _playbackVersion) {
        setState(() => _speaking = false);
      }
    }
  }

  Future<void> _stop() async {
    ++_playbackVersion;

    setState(() {
      _speaking = false;
    });

    try {
      await _speechService.stop();
    } catch (e) {
      debugPrint('SightMate stop error: $e');
    }
  }

  Future<void> _updateRate(double rate) async {
    setState(() {
      _speechRate = rate;
    });

    try {
      await _speechService.setSpeechRate(rate);
    } catch (e) {
      debugPrint('SightMate speech rate error: $e');
    }
  }

  @override
  void dispose() {
    ++_playbackVersion;
    _speechService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFrench = _language == SpeechLanguage.french;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFrench ? 'Synthèse vocale' : 'Text to Speech'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.record_voice_over_outlined,
              color: Color(0xFF93C5FD),
              size: 72,
            ),
            const SizedBox(height: 24),

            Text(
              isFrench ? 'Choisissez la langue' : 'Choose your language',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 24),

            // Sélecteur de langue accessible.
            SegmentedButton<SpeechLanguage>(
              showSelectedIcon: true,
              segments: const [
                ButtonSegment(
                  value: SpeechLanguage.french,
                  label: Text('Français'),
                  icon: Icon(Icons.language),
                ),
                ButtonSegment(
                  value: SpeechLanguage.english,
                  label: Text('English'),
                  icon: Icon(Icons.language),
                ),
              ],
              selected: {_language},
              onSelectionChanged: _ready && !_busy
                  ? (selection) {
                      _changeLanguage(selection.first);
                    }
                  : null,
            ),

            const SizedBox(height: 24),

            Semantics(
              liveRegion: true,
              child: Text(
                !_ready
                    ? (_error ?? 'Initialisation de la voix...')
                    : _busy
                    ? (isFrench
                          ? 'Changement de langue...'
                          : 'Changing language...')
                    : _speaking
                    ? (isFrench ? 'Lecture en cours' : 'Speaking')
                    : (isFrench ? 'Voix prête' : 'Voice ready'),
                textAlign: TextAlign.center,
              ),
            ),

            if (_error != null && _ready) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _ready && !_busy && !_speaking ? _speak : null,
              icon: const Icon(Icons.volume_up),
              label: Text(isFrench ? 'Écouter le message' : 'Play message'),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _speaking ? _stop : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(isFrench ? 'Arrêter' : 'Stop'),
            ),

            const SizedBox(height: 32),

            Text(
              isFrench
                  ? 'Vitesse de lecture : '
                        '${_speechRate.toStringAsFixed(2)}'
                  : 'Speech rate: '
                        '${_speechRate.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            Slider(
              min: 0.25,
              max: 0.85,
              divisions: 12,
              value: _speechRate,
              label: _speechRate.toStringAsFixed(2),
              onChanged: _ready && !_busy && !_speaking ? _updateRate : null,
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _language.sampleMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
