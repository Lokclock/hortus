import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/utils/map_math.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/widgets/crosshair.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';
import '../providers/map_mode_provider.dart';

class PositioningOverlay extends ConsumerWidget {
  final String gardenId;

  const PositioningOverlay({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);

    if (mode == MapMode.view) return const SizedBox();

    return Stack(
      children: [
        // assombrissement
        IgnorePointer(
          ignoring: true, // ne bloque pas les gestes en dehors des boutons
          child: Container(color: Colors.black.withOpacity(0.1)),
        ),

        /// Viseur centré
        const Center(child: Crosshair()),

        /// Boutons validation
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton.extended(
                heroTag: "cancel",
                backgroundColor: Colors.red,
                label: const Text("Annuler"),
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(mapModeProvider.notifier).state = MapMode.view;
                },
              ),
              const SizedBox(width: 24),
              FloatingActionButton.extended(
                heroTag: "confirm",
                backgroundColor: Colors.green,
                label: const Text("Valider position"),
                icon: const Icon(Icons.check),
                onPressed: () async {
                  final controller = ref.read(mapTransformProvider);
                  final size = MediaQuery.of(context).size;

                  final pos = getWorldPosition(
                    controller: controller,
                    viewportSize: size,
                  );

                  final plantData = ref.read(addPlantProvider);
                  final repo = ref.read(plantRepoProvider);

                  if (plantData.id != null && plantData.id!.isNotEmpty) {
                    // Mise à jour existante
                    await repo.updatePlant(
                      Plant(
                        id: plantData.id!,
                        gardenId: gardenId,
                        name: plantData.name ?? "",
                        x: pos.dx,
                        y: pos.dy,
                        type: plantData.type ?? "default",
                      ),
                    );
                  } else {
                    // Nouvelle plante
                    await repo.addPlant(
                      Plant(
                        id: "",
                        gardenId: gardenId,
                        name: plantData.name ?? "",
                        x: pos.dx,
                        y: pos.dy,
                        type: plantData.type ?? "default",
                      ),
                    );
                  }

                  ref.read(mapModeProvider.notifier).state = MapMode.view;
                  ref.read(addPlantProvider.notifier).state =
                      const AddPlantState();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
