import 'package:material_ui/material_ui.dart';

class CameraIconButton extends StatelessWidget {
  const CameraIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          minimumSize: const Size(52, 52),
        ),
        icon: Icon(icon, size: 26),
      ),
    );
  }
}
