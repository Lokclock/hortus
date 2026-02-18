import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/views/garden_canvas.dart';
import '../../plants/providers/plant_providers.dart';

class GardenMapPage extends ConsumerWidget {
  final String gardenId;
  final bool canEdit;

  const GardenMapPage({
    super.key,
    required this.gardenId,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsStreamProvider(gardenId));

    return Scaffold(
      appBar: AppBar(title: const Text("Carte du jardin")),
      body: plantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur: $e")),
        data: (plants) {
          return GardenCanvas(
            gardenId: gardenId,
            plants: plants,
            canEdit: canEdit,
          );
        },
      ),
    );
  }
}
