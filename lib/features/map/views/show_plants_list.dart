// Widget bottom sheet plantes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/widgets/app_list_tile.dart';
import 'package:hortus_app/features/map/providers/garden_permissions_provider.dart';
import 'package:hortus_app/features/map/views/plant_details_sheet.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';

void showPlantsList(BuildContext context, WidgetRef ref, String gardenId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SafeArea(
      child: Consumer(
        builder: (context, ref, _) {
          final canEdit = ref.watch(canEditGardenProvider(gardenId));
          final plantsAsync = ref.watch(plantsStreamProvider(gardenId));
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: plantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Erreur : $e")),
              data: (plants) => _PlantsList(
                plants: plants,
                canEdit: canEdit,
                gardenId: gardenId,
              ),
            ),
          );
        },
      ),
    ),
  );
}

// Widget de la liste avec recherche
class _PlantsList extends StatefulWidget {
  final String gardenId;
  final bool canEdit;
  final List plants;
  const _PlantsList({
    super.key,
    required this.plants,
    required this.canEdit,
    required this.gardenId,
  });

  @override
  State<_PlantsList> createState() => _PlantsListState();
}

class _PlantsListState extends State<_PlantsList> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.plants.where((plant) {
      final name = plant.name.toLowerCase();
      final scientific = plant.scientificName?.toLowerCase() ?? '';
      final variety = plant.variety?.toLowerCase() ?? '';
      final q = query.toLowerCase();
      return name.contains(q) || scientific.contains(q) || variety.contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Rechercher une plante...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => query = val),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 0, color: Colors.transparent),
                  itemBuilder: (_, i) {
                    final plant = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4.0,
                      ),
                      child: AppListTile(
                        leading: plant.imageUrl != null
                            ? Image.network(
                                plant.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.local_florist, size: 40),
                        title: plant.name,
                        subtitle:
                            "${plant.scientificName ?? ""}${plant.variety != null ? " • ${plant.variety}" : ""}",
                        trailing: IconButton(
                          icon: const Icon(Icons.place),
                          onPressed: () {
                            // TODO : centrer la carte sur la plante
                          },
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => PlantDetailsSheet(
                              gardenId: widget.gardenId,
                              plantId: plant.id,
                              canEdit: widget.canEdit,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
