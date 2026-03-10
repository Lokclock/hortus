import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';
import 'package:hortus_app/features/map/views/add_plant_page.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_edit_button.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_gallery.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_harvest_row.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_header.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_info_bar.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_observations_card.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_planted_date.dart';
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
                      PlantHeader(plant: plant),

                      const SizedBox(height: 12),

                      PlantInfoBar(plant: plant),

                      const SizedBox(height: 12),

                      PlantHarvestRow(plant: plant),

                      const SizedBox(height: 12),

                      PlantObservationsCard(plant: plant),

                      const SizedBox(height: 12),

                      plant.images?.isNotEmpty ?? false
                          ? PlantGallery(images: plant.images!)
                          : Container(
                              decoration: AppDecorations.block,

                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              child: Text(
                                'Galerie',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),

                      const SizedBox(height: 12),

                      PlantPlantedDate(plant: plant),

                      const SizedBox(height: 12),
                      PlantEditButton(
                        onPressed: () {
                          ref
                              .read(addPlantProvider.notifier)
                              .startMovePlant(plant);

                          ref.read(mapModeProvider.notifier).state =
                              MapMode.addPlant;

                          Navigator.pop(context);
                        },
                      ),
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
