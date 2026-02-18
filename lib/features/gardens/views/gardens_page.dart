import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/features/gardens/models/garden_model.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';

class GardensPage extends ConsumerStatefulWidget {
  const GardensPage({super.key});

  @override
  ConsumerState<GardensPage> createState() => _GardensPageState();
}

class _GardensPageState extends ConsumerState<GardensPage> {
  int selectedFilter = 0;

  final filters = ["Tous", "Mes jardins", "Publics"];

  @override
  Widget build(BuildContext context) {
    final gardensAsync = ref.watch(accessibleGardensProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mes jardins")),
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// FILTRES
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(filters.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(filters[index]),
                  selected: selectedFilter == index,
                  onSelected: (_) {
                    setState(() => selectedFilter = index);
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          /// LISTE FIRESTORE
          Expanded(
            child: gardensAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, _) => Center(child: Text("Erreur : $e")),

              data: (gardens) {
                /// 🔹 Appliquer filtre UI
                List<Garden> filtered = gardens;

                if (selectedFilter == 1) {
                  filtered = gardens.where((g) => !g.isPublic).toList();
                } else if (selectedFilter == 2) {
                  filtered = gardens.where((g) => g.isPublic).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text("Aucun jardin 🌱"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final garden = filtered[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.park),
                        title: Text(garden.name),
                        subtitle: Text("${garden.width}m x ${garden.height}m"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go('/garden/${garden.id}');
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
