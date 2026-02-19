import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/views/add_plant_page.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                  // 🌸 IMAGE PRINCIPALE
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Center(
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
                                child: const Icon(
                                  Icons.local_florist,
                                  size: 64,
                                ),
                              ),
                      ),
                    ),
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // 🌱 NOM, SCIENTIFIQUE, VARIÉTÉ
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Diamètre + recentrer
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Row(
                      children: [
                        const Icon(Icons.straighten),
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
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Récolte et Strate
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Row(
                      children: [
                        Text('Récolte: ${plant.harvestType ?? '-'}'),
                        const SizedBox(width: 16),
                        Text('Strate: ${plant.strate ?? '-'}'),
                      ],
                    ),
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Observations
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        ...plant.observations?.map((obs) {
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
                      ],
                    ),
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Galerie
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Date plantation
                  _buildEditableContainer(
                    context,
                    canEdit: canEdit,
                    child: Text(
                      'Planté le: ${plant.plantedAt?.toLocal().toString().split(' ')[0] ?? '-'}',
                    ),
                    onTap: canEdit
                        ? () => _openAddPlantPage(context, plant)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Bouton Déplacer
                  if (canEdit)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _openAddPlantPage(context, plant),
                        icon: const Icon(Icons.open_with),
                        label: const Text('Déplacer / Modifier'),
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

  /// Widget générique pour chaque bloc éditable
  Widget _buildEditableContainer(
    BuildContext context, {
    required Widget child,
    required bool canEdit,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: canEdit ? Border.all(color: Colors.green.shade300) : null,
      ),
      child: InkWell(onTap: canEdit ? onTap : null, child: child),
    );
  }

  void _openAddPlantPage(BuildContext context, Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlantPage(gardenId: gardenId, plant: plant),
      ),
    );
  }
}
