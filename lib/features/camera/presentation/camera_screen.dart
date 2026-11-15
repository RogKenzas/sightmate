import 'dart:io';

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sightmate/core/service/speech_service.dart';
import 'package:sightmate/features/speech/domains/speech_message.dart';

import '../../../components/camera_icon_button.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final SpeechService _speechService = SpeechService.instance;

  XFile? _photo;
  String? _error;
  bool _loading = true;
  bool _capturing = false;
  int _cameraIndex = 0;
  int _generation = 0;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadCameras();

    _speechService.initialize().catchError((Object error) {
      debugPrint('SightMate speech initialization: $error');
    });
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      _cameras = cameras;
      final rearIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = rearIndex < 0 ? 0 : rearIndex;

      await _startCamera();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible d’accéder à la caméra : $e';
        _loading = false;
      });
    }
  }

  Future<void> _startCamera() async {
    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Aucune caméra disponible.';
          _loading = false;
        });
      }
      return;
    }

    final generation = ++_generation;
    final oldController = _controller;
    _controller = null;

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    await oldController?.dispose();

    if (!mounted || generation != _generation) return;

    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }

      await controller.setFlashMode(FlashMode.off);
      _flashMode = FlashMode.off;
      _controller = controller;

      setState(() {
        _loading = false;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      if (!mounted || generation != _generation) return;

      setState(() {
        _error = e.code == 'CameraAccessDenied'
            ? 'Autorise la caméra dans les paramètres Android.'
            : 'Erreur caméra : ${e.description ?? e.code}';
        _loading = false;
      });
    } catch (e) {
      await controller.dispose();
      if (!mounted || generation != _generation) return;

      setState(() {
        _error = 'Impossible de démarrer la caméra : $e';
        _loading = false;
      });
    }
  }

  Future<void> _capture() async {
    // Lorsque la photo est déjà affichée,
    // permettre de revenir à la caméra.
    if (_photo != null) {
      setState(() => _photo = null);
      return;
    }

    final camera = _controller;

    if (camera == null || !camera.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);

    try {
      final photo = await camera.takePicture();

      if (!mounted) return;

      setState(() {
        _photo = photo;
        _capturing = false;
      });

      // Annonce dans la langue sélectionnée.
      final message = SpeechMessages.photoCaptured(_speechService.language);

      // Le TTS n'est pas nécessaire pour réussir la capture.
      // Il possède donc sa propre gestion d'erreur.
      try {
        await _speechService.speak(message);
      } catch (error) {
        debugPrint('SightMate TTS error: $error');
      }
    } catch (error) {
      debugPrint('SightMate capture error: $error');

      if (!mounted) return;

      _showMessage('Impossible de prendre la photo.');

      try {
        await _speechService.initialize();

        await _speechService.speak(
          SpeechMessages.captureFailed(_speechService.language),
        );
      } catch (speechError) {
        debugPrint('SightMate speech error: $speechError');
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _controller;
    if (camera == null || !camera.value.isInitialized) return;

    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;

    try {
      await camera.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      _showMessage('Flash non disponible sur cette caméra.');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing || _loading) return;

    setState(() {
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      _photo = null;
    });
    await _startCamera();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      ++_generation;
      final old = _controller;
      _controller = null;
      old?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && !_loading) {
        _startCamera();
      } else if (_controller == null) {
        _startCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),

          // Assombrissement léger des zones périphériques.
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  stops: [0, 0.25, 0.60, 1],
                ),
              ),
            ),
          ),

          // Zone de cadrage au centre de l'écran.
          const Center(child: IgnorePointer(child: _ScanFrame())),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 28),
                _buildStatusBadge(),
                const Spacer(),
                _buildInfoPanel(),
                const SizedBox(height: 22),
                _buildBottomBar(),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_photo != null) {
      return Image.file(File(_photo!.path), fit: BoxFit.cover);
    }

    final camera = _controller;
    if (camera == null || !camera.value.isInitialized || _loading) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
      );
    }

    final size = camera.value.previewSize!;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(camera),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CameraIconButton(
            icon: Icons.close,
            tooltip: 'Fermer la caméra',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'SightMate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          CameraIconButton(
            icon: _flashMode == FlashMode.off
                ? Icons.flash_off
                : Icons.flash_on,
            tooltip: _flashMode == FlashMode.off
                ? 'Activer le flash'
                : 'Désactiver le flash',
            onPressed: _loading || _photo != null ? null : _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final text = _photo == null ? 'Caméra prête à capturer' : 'Photo capturée';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _photo == null ? 'Décrire mon environnement' : 'Image capturée',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _photo == null
                  ? 'Orientez la caméra vers votre environnement.'
                  : 'Photo prête. L’analyse IA sera intégrée '
                        'dans la prochaine étape.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'L’analyse automatique n’est pas encore active.',
              style: TextStyle(color: Color(0xFFBBDEFB), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: _photo == null
                ? const Icon(
                    Icons.image_outlined,
                    color: Colors.white70,
                    size: 30,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(_photo!.path), fit: BoxFit.cover),
                  ),
          ),
          Semantics(
            button: true,
            label: _photo == null ? 'Prendre une photo' : 'Reprendre une photo',
            child: GestureDetector(
              onTap: _loading || _capturing ? null : _capture,
              child: Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _capturing
                      ? const Padding(
                          padding: EdgeInsets.all(17),
                          child: CircularProgressIndicator(),
                        )
                      : _photo != null
                      ? const Icon(Icons.refresh, color: Colors.black, size: 30)
                      : null,
                ),
              ),
            ),
          ),
          CameraIconButton(
            icon: Icons.cameraswitch_outlined,
            tooltip: 'Changer de caméra',
            onPressed:
                _cameras.length > 1 &&
                    !_loading &&
                    !_capturing &&
                    _photo == null
                ? _switchCamera
                : null,
          ),
        ],
      ),
    );
  }
}

// Cadre de détection décoratif : pas de détection IA active.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(painter: _ScanFramePainter()),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const length = 34.0;
    const radius = 17.0;

    final path = Path()
      ..moveTo(0, length)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(length, 0)
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, length)
      ..moveTo(size.width, size.height - length)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(size.width - length, size.height)
      ..moveTo(length, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, size.height - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
