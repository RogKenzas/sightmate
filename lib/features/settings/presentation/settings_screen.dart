
import 'package:material_ui/material_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text(
              'Accessibilité',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.volume_up_outlined),
                    title: Text('Retour vocal'),
                    subtitle: Text(
                      'Disponible dans la Phase 2',
                    ),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.vibration),
                    title: Text('Vibrations'),
                    subtitle: Text(
                      'Disponible dans la Phase 2',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'À propos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('SightMate'),
              subtitle: Text(
                'Version MVP — Phase 1',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
