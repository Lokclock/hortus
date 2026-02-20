import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/utils/map_math.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/widgets/crosshair.dart';
import 'package:hortus_app/features/map/widgets/diameter_preview.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';
import '../providers/map_mode_provider.dart';

class PositioningOverlay extends ConsumerWidget {
  final String gardenId;

  const PositioningOverlay({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
    final plantData = ref.watch(addPlantProvider);

    // Si on est en mode view, rien à afficher
    if (mode == MapMode.view) return const SizedBox();

    // Vérifie que les champs obligatoires sont remplis
    final isReadyToPlant =
        plantData.name != null &&
        plantData.name!.isNotEmpty &&
        plantData.strate != null &&
        plantData.strate!.isNotEmpty &&
        plantData.icon != null &&
        plantData.icon!.isNotEmpty &&
        plantData.diameter != null;

    return Stack(
      children: [
        // assombrissement
        IgnorePointer(
          ignoring: true,
          child: Container(color: Colors.black.withOpacity(0.1)),
        ),

        const DiameterPreview(),

        // Viseur centré
        const Center(child: Crosshair()),

        // Bouton planter
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.extended(
              heroTag: "plant",
              backgroundColor: isReadyToPlant ? Colors.green : Colors.grey,
              label: const Text("Planter!"),
              icon: const Icon(Icons.check),
              onPressed: isReadyToPlant
                  ? () async {
                      final controller = ref.read(mapTransformProvider);
                      final size = MediaQuery.of(context).size;

                      final pos = getWorldPosition(
                        controller: controller,
                        viewportSize: size,
                      );

                      final repo = ref.read(plantRepoProvider);

                      final newPlant = Plant(
                        id: plantData.id ?? "",
                        gardenId: gardenId,
                        name: plantData.name!,
                        scientificName: plantData.scientificName,
                        variety: plantData.variety,
                        x: pos.dx,
                        y: pos.dy,
                        diameter: plantData.diameter!,
                        harvestType: plantData.harvestType ?? {},
                        strate: plantData.strate!,
                        icon: plantData.icon!,
                        plantedAt: plantData.plantedAt ?? DateTime.now(),
                      );

                      if (plantData.id != null && plantData.id!.isNotEmpty) {
                        await repo.updatePlant(newPlant);
                      } else {
                        await repo.addPlant(newPlant);
                      }

                      // Reset le provider et repasse en mode view
                      ref.read(addPlantProvider.notifier).state =
                          const AddPlantState();
                      ref.read(mapModeProvider.notifier).state = MapMode.view;
                    }
                  : null, // désactive si champs obligatoires manquants
            ),
          ),
        ),
      ],
    );
  }
}
