import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';

class GardenMapPage extends ConsumerWidget {
  final String gardenId;

  const GardenMapPage({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardens = ref.watch(gardensStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Carte du jardin")),
      body: gardens.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) {
          final garden = list.firstWhere((g) => g.id == gardenId);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garden.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text("Taille : ${garden.width}m x ${garden.height}m"),

                const SizedBox(height: 10),

                Text(
                  garden.isPublic ? "Public" : "Privé",
                  style: TextStyle(
                    color: garden.isPublic ? Colors.green : Colors.red,
                  ),
                ),

                if (garden.isPublic)
                  Text(
                    garden.isEditable ? "Modifiable par tous" : "Lecture seule",
                    style: TextStyle(
                      color: garden.isEditable ? Colors.blue : Colors.orange,
                    ),
                  ),

                const SizedBox(height: 30),

                /// PLACEHOLDER FUTURE CARTE
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        "🗺️ Carte interactive à venir",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
