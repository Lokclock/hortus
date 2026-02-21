import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';

class GardenSettingsPage extends ConsumerWidget {
  final String gardenId;

  const GardenSettingsPage({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(gardenProvider(gardenId));

    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres du jardin")),
      body: gardenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
        data: (garden) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Field("Longueur", "${garden.length} m"),
              _Field("Largeur", "${garden.width} m"),
              _Field("Visibilité", garden.isPublic ? "Public" : "Privé"),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Changer image de fond"),
                onPressed: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label), trailing: Text(value));
  }
}
