import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';

class PlantDetailsSheet extends ConsumerWidget {
  final String gardenId;
  final String plantId;
  final bool canEdit;

  const PlantDetailsSheet({
    super.key,
    required this.gardenId,
    required this.plantId,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(
      plantByIdProvider(PlantKey(gardenId: gardenId, plantId: plantId)),
    );

    return plantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (plant) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌸 Image principale
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: plant.imageUrl != null
                          ? Image.network(
                              plant.imageUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 150,
                              height: 150,
                              color: Colors.green.shade100,
                              child: const Icon(Icons.local_florist, size: 64),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🌱 Nom
                  Text(
                    plant.commonName ?? plant.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plant.scientificName != null)
                    Text(
                      plant.scientificName!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  if (plant.variety != null) Text(plant.variety!),
                  const SizedBox(height: 12),

                  // Diamètre + recentrer
                  Row(
                    children: [
                      Icon(Icons.local_florist),
                      const SizedBox(width: 8),
                      Text('Diamètre: ${plant.diameter ?? 0} cm'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.center_focus_strong),
                        onPressed: () {
                          // TODO: recentrer sur la carte
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Récolte et Strate
                  Row(
                    children: [
                      Text('Récolte: ${plant.harvestType ?? '-'}'),
                      const SizedBox(width: 16),
                      Text('Strate: ${plant.strate ?? '-'}'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Observations
                  Text(
                    'Observations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Column(
                    children:
                        plant.observations?.map((obs) {
                          final date = obs['date'] as Timestamp?;
                          return ListTile(
                            title: Text(obs['text'] ?? ''),
                            subtitle: Text(
                              date != null
                                  ? date.toDate().toLocal().toString()
                                  : '',
                            ),
                          );
                        }).toList() ??
                        [const Text('Aucune observation')],
                  ),
                  const SizedBox(height: 12),

                  // Galerie
                  Text(
                    'Galerie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: plant.images?.length ?? 0,
                      itemBuilder: (context, i) {
                        final img = plant.images![i];
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              img,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date plantation
                  Text(
                    'Planté le: ${plant.plantedAt?.toLocal().toString().split(' ')[0] ?? '-'}',
                  ),
                  const SizedBox(height: 12),

                  // Bouton Déplacer (si canEdit)
                  if (canEdit)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 1️⃣ Pré-remplir addPlantProvider
                          final addPlantNotifier = ref.read(
                            addPlantProvider.notifier,
                          );
                          addPlantNotifier.state = AddPlantState(
                            id: plant.id,
                            name: plant.name,
                            type: plant.type,
                            // ajouter plus de champs si nécessaire
                          );

                          // 2️⃣ Passer en mode édition
                          ref.read(mapModeProvider.notifier).state =
                              MapMode.edit;

                          // 3️⃣ Fermer la fiche
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.open_with),
                        label: const Text('Déplacer'),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
