import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';

class DiameterPreview extends ConsumerWidget {
  final double tilePixelSize = 32; // taille tile en px
  final double tileCmSize = 20; // taille tile en cm

  const DiameterPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plant = ref.watch(addPlantProvider);
    final mapTransform = ref.watch(mapTransformProviderNotifier);

    if (plant.diameter == null || plant.diameter! <= 0) {
      return const SizedBox();
    }
    final diameterPx =
        plant.diameter! * (tilePixelSize / tileCmSize) * mapTransform.scale;

    return IgnorePointer(
      child: Center(
        child: Container(
          width: diameterPx,
          height: diameterPx,
          decoration: BoxDecoration(
            shape: BoxShape.circle,

            color: Colors.green.withOpacity(0.15),
            border: Border.all(
              color: const Color.fromARGB(255, 240, 67, 67).withOpacity(0.6),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
