import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/utils/map_math.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';

class DiameterPreview extends ConsumerWidget {
  const DiameterPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plant = ref.watch(addPlantProvider);
    final controller = ref.watch(mapTransformProvider);

    // Rien si pas de diamètre
    if (plant.diameter == null || plant.diameter! <= 0) {
      return const SizedBox();
    }

    /// IMPORTANT :
    /// AnimatedBuilder écoute automatiquement le controller
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final diameterPx = worldCmToScreenPx(
          controller: controller,
          cm: plant.diameter!,
        );

        final radius = diameterPx / 2;

        return IgnorePointer(
          child: Center(
            child: Container(
              width: diameterPx,
              height: diameterPx,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.15),
                border: Border.all(
                  color: Colors.green.withOpacity(0.6),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
