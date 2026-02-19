import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/providers/selected_plant_provider.dart';
import 'package:hortus_app/features/map/views/plant_details_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class GardenCanvas extends ConsumerWidget {
  final String gardenId;
  final List<Plant> plants;
  final bool canEdit;

  const GardenCanvas({
    super.key,
    required this.gardenId,
    required this.plants,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transformController = ref.watch(mapTransformProvider);

    return InteractiveViewer(
      transformationController: transformController,
      maxScale: 4,
      minScale: 0.5,
      child: Container(
        width: 2000,
        height: 2000,
        color: Colors.green.shade50,
        child: Stack(
          children: plants.map((p) {
            return Positioned(
              left: p.x,
              top: p.y,
              child: GestureDetector(
                onTap: () {
                  // On ouvre la fiche plante quel que soit canEdit
                  ref.read(selectedPlantProvider.notifier).state = p;

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => PlantDetailsSheet(
                      plantId: p.id,
                      gardenId: gardenId,
                      canEdit: canEdit,
                    ),
                  );

                  print('Tap plant: gardenId=$gardenId, plantId=${p.id}');
                },
                child: Icon(
                  Icons.local_florist,
                  color: Colors.green,
                  size: p.diameter ?? 32,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
