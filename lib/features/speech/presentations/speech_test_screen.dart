import 'package:material_ui/material_ui.dart';
import 'package:sightmate/core/service/speech_service.dart';

class SpeechTestScreen extends StatefulWidget {
  const SpeechTestScreen({super.key});

  @override
  State<SpeechTestScreen> createState() => _SpeechTestScreenState();
}

class _SpeechTestScreenState extends State<SpeechTestScreen> {
  final SpeechService _speechService = SpeechService();

  final String _testMessage =
      'Bonjour, bienvenue sur SightMate. '
      'Votre assistant visuel est prêt à vous accompagner.';

  double _speechRate = 0.5;
  bool _ready = false;
  bool _speaking = false;
  String _status = 'Initialisation de la voix...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _speechService.initialize();

      final available = await _speechService.isFrenchAvailable();

      if (!mounted) return;

      setState(() {
        _ready = true;
        _status = available
            ? 'Voix française disponible'
            : 'Voix française à vérifier sur cet appareil';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Impossible d’initialiser la synthèse vocale';
      });

      debugPrint('SightMate TTS initialization error: $e');
    }
  }

  Future<void> _speak() async {
    if (!_ready || _speaking) return;

    setState(() {
      _speaking = true;
      _status = 'Lecture en cours...';
    });

    try {
      await _speechService.speak(_testMessage);

      if (!mounted) return;

      setState(() {
        _status = 'Lecture terminée';
      });
    } catch (e) {
      debugPrint('SightMate TTS speak error: $e');

      if (!mounted) return;

      setState(() {
        _status = 'Erreur pendant la lecture vocale';
      });
    } finally {
      if (mounted) {
        setState(() => _speaking = false);
      }
    }
  }

  Future<void> _stop() async {
    try {
      await _speechService.stop();

      if (!mounted) return;

      setState(() {
        _speaking = false;
        _status = 'Lecture arrêtée';
      });
    } catch (e) {
      debugPrint('SightMate TTS stop error: $e');
    }
  }

  Future<void> _updateRate(double rate) async {
    setState(() => _speechRate = rate);

    try {
      await _speechService.setSpeechRate(rate);
    } catch (e) {
      debugPrint('SightMate TTS rate error: $e');
    }
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test vocal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.record_voice_over_outlined,
              size: 72,
              color: Color(0xFF93C5FD),
            ),
            const SizedBox(height: 24),

            Text(
              'Synthèse vocale SightMate',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              'Testez la lecture vocale de votre assistant '
              'directement sur votre smartphone.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Semantics(
              liveRegion: true,
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _ready && !_speaking ? _speak : null,
              icon: const Icon(Icons.volume_up),
              label: const Text('Écouter le message'),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _ready ? _stop : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Arrêter la lecture'),
            ),

            const SizedBox(height: 36),

            Text(
              'Vitesse de lecture : '
              '${_speechRate.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            Slider(
              min: 0.25,
              max: 0.85,
              divisions: 12,
              value: _speechRate,
              label: _speechRate.toStringAsFixed(2),
              onChanged: _ready && !_speaking ? _updateRate : null,
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _testMessage,
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
