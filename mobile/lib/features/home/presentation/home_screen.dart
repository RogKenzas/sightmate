import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:sightmate/components/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SightMate'),
        actions: [
          IconButton(
            tooltip: 'Ouvrir les paramètres',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bonjour !',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comment puis-je vous aider ?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            FeatureCard(
              icon: Icons.camera_alt_outlined,
              title: 'Décrire mon environnement',
              description: 'Analyse de votre environnement par caméra.',
              onTap: () => context.push('/camera'),
            ),
            const SizedBox(height: 16),

            FeatureCard(
              icon: Icons.document_scanner_outlined,
              title: 'Lire un texte',
              description: 'Lecture de documents, panneaux et étiquettes.',
            ),
            const SizedBox(height: 32),

            const Text(
              'SightMate est une aide complémentaire '
              'et ne remplace pas les dispositifs '
              'de déplacement adaptés.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
