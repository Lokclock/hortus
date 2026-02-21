import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/core/widgets/app_list_tile.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';
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
    final theme = Theme.of(context);
    final gardensAsync = ref.watch(accessibleGardensProvider);
    final currentUserId = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox(width: 0, height: 0),
        title: Text(
          "H o r t u s",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),

          /// 🌿 FILTRES PREMIUM
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final selected = selectedFilter == index;

                return ChoiceChip(
                  label: Text(filters[index]),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedFilter = index),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: filters.length,
            ),
          ),

          const SizedBox(height: 16),

          /// 🌿 LISTE
          Expanded(
            child: gardensAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, _) => Center(child: Text("Erreur : $e")),

              data: (gardens) {
                List<Garden> filtered = gardens;

                if (selectedFilter == 1 && currentUserId != null) {
                  filtered = gardens
                      .where((g) => g.ownerId == currentUserId)
                      .toList();
                } else if (selectedFilter == 2) {
                  filtered = gardens.where((g) => g.isPublic).toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text("Aucun jardin 🌱"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final garden = filtered[i];

                    return AppListTile(
                      leading: const Icon(Icons.park),
                      title: garden.name,
                      subtitle: "par ${garden.ownerUsername ?? "Inconnu"}",
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/garden/${garden.id}'),
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
