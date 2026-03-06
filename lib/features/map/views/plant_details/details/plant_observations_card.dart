import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:go_router/go_router.dart';

class PlantObservationsCard extends ConsumerWidget {
  final Plant plant;

  const PlantObservationsCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obsCount = plant.observations?.length ?? 0;

    return InkWell(
      onTap: () {
        context.push('/observations-chat/${plant.id}');
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
              child: Text(
                obsCount > 0
                    ? 'Observations ($obsCount)'
                    : 'Aucune observation',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (obsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$obsCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
