import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/views/add_plant_page.dart';
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // ton vrai fond
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 IMAGE + NOM / SCIENTIFIQUE / VARIÉTÉ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image principale
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: plant.imageUrl != null
                                ? Image.network(
                                    plant.imageUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.green.shade100,
                                    child: const Icon(
                                      Icons.local_florist,
                                      size: 64,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Nom / scientifique / variété
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (plant.scientificName != null)
                                  Text(
                                    plant.scientificName!,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                if (plant.variety != null) Text(plant.variety!),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 🔹 SYMBOLE + DIAMÈTRE + DRAPEAU
                      Container(
                        padding: const EdgeInsets.only(
                          left: 12,
                          top: 4,
                          bottom: 4,
                          right: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Symbole
                            plant.symbol != null
                                ? Image.asset(
                                    plant.symbol!,
                                    width: 80,
                                    height: 80,
                                  )
                                : const SizedBox(width: 40, height: 40),

                            // Diamètre
                            Text('${plant.diameter} cm'),
                            Container(
                              padding: const EdgeInsets.all(12),
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.place),
                                onPressed: () {
                                  // TODO: localiser sur la carte
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 RÉCOLTES + STRATE
                      Container(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  right: 12,
                                  top: 8,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Récoltes (max 5)
                                    Expanded(
                                      child: Row(
                                        children: List.generate(5, (i) {
                                          if (i <
                                              (plant.harvestType?.length ??
                                                  0)) {
                                            final type = plant.harvestType!.keys
                                                .elementAt(i);
                                            final imgPath =
                                                'assets/images/recoltes/$type.png';
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Image.asset(
                                                imgPath,
                                                width: 40,
                                                height: 40,
                                              ),
                                            );
                                          }
                                          return const SizedBox(
                                            width: 30,
                                            height: 30,
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Container(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  right: 12,
                                  top: 8,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  'assets/images/strates/${plant.strate}.png',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 OBSERVATIONS
                      InkWell(
                        onTap: () {
                          // TODO: ouvrir page type chat pour observations
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plant.observations?.isNotEmpty == true
                                ? 'Observations (${plant.observations!.length})'
                                : 'Aucune observation',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 GALERIE
                      if ((plant.images?.isNotEmpty ?? false))
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: plant.images!.length,
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

                      // 🔹 DATE PLANTATION
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Planté le: ${plant.plantedAt.toLocal().toString().split(' ')[0]}',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 BOUTON DÉPLACER
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
            ),
          ),
        );
      },
    );
  }

  void _openAddPlantPage(BuildContext context, Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPlantPage(gardenId: gardenId)),
    );
  }
}
