import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/features/plants/providers/observation_provider.dart';

class PlantObservationsCard extends ConsumerWidget {
  final Plant plant;

  const PlantObservationsCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utilise ton StreamProvider pour compter les observations
    final obsAsync = ref.watch(
      messagesProvider((gardenId: plant.gardenId, plantId: plant.id)),
    );

    return InkWell(
      onTap: () {
        context.push('/observations-chat/${plant.gardenId}/${plant.id}');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: AppDecorations.block,
        child: Row(
          children: [
            const Icon(Icons.chat, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: obsAsync.when(
                data: (obs) {
                  final obsCount = obs.length;
                  return Text(
                    obsCount > 0 ? 'Observations' : 'Aucune observation',
                    style: const TextStyle(fontSize: 16),
                  );
                },
                loading: () => const Text('Chargement...'),
                error: (_, __) => const Text('Erreur'),
              ),
            ),
            obsAsync.when(
              data: (obs) => obs.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${obs.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
