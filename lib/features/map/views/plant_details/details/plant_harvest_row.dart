import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/constants/app_assets.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/map/providers/edit_plant_provider.dart';
import 'package:hortus_app/features/map/views/plant_details/edit/edit_harvest_sheet.dart';
import 'package:hortus_app/features/map/views/plant_details/edit/edit_strate_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class PlantHarvestRow extends ConsumerWidget {
  final Plant plant;

  const PlantHarvestRow({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute l'état de la plante en édition
    final editState = ref.watch(editPlantProvider(plant));

    final currentStrate = editState.strate ?? plant.strate;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => EditHarvestSheet(plant: plant),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
              decoration: AppDecorations.block,
              child: Row(
                children: List.generate(5, (i) {
                  if (i < (plant.harvestType?.length ?? 0)) {
                    final type = plant.harvestType!.keys.elementAt(i);
                    final imgPath = AppAssets.harvest[type];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: imgPath != null
                          ? Image.asset(imgPath, width: 40, height: 40)
                          : Container(
                              color: Colors.blue,
                              width: 40,
                              height: 40,
                            ),
                    );
                  }

                  return const SizedBox(width: 40, height: 40);
                }),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EditStrateSheet(plant: plant),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: AppDecorations.block,
            child: Image.asset(
              AppAssets.strates[currentStrate]!, // ← maintenant lié au provider
              width: 50,
              height: 50,
            ),
          ),
        ),
      ],
    );
  }
}
