import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/garden_permissions_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';
import 'package:hortus_app/features/map/views/add_plant_page.dart';
import 'package:hortus_app/features/map/views/garden_canvas.dart';
import 'package:hortus_app/features/map/views/positioning_overlay.dart';
import '../../plants/providers/plant_providers.dart';

class GardenMapPage extends ConsumerWidget {
  final String gardenId;

  const GardenMapPage({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsStreamProvider(gardenId));
    final canEdit = ref.watch(canEditGardenProvider(gardenId));

    return Scaffold(
      body: Stack(
        children: [
          /// 🌿 MAP
          plantsAsync.when(
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

          /// 🔝 MINI TOP BAR
          _TopMapBar(),

          /// 🔻 FLOATING BOTTOM BAR
          _BottomMapBar(canEdit: canEdit, gardenId: gardenId),

          PositioningOverlay(gardenId: gardenId),
        ],
      ),
    );
  }
}

class _TopMapBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
    if (mode == MapMode.addPlant) return const SizedBox();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.push('/home');
                },
              ),
              const SizedBox(width: 8),
              const Text(
                "Nom du jardin",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.center_focus_strong),
                onPressed: () {
                  /// plus tard : reset viewport
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomMapBar extends ConsumerWidget {
  final bool canEdit;
  final String gardenId;

  const _BottomMapBar({required this.canEdit, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
    if (mode == MapMode.addPlant) return const SizedBox();
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// FILTERS
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  /// plus tard : ouvrir panel filtres
                },
              ),

              const SizedBox(width: 24),

              /// LIST PLANTS
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {
                  /// plus tard : ouvrir drawer plantes
                },
              ),

              const SizedBox(width: 24),

              /// ADD PLANT
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 32),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.9,
                            ),
                            child: AddPlantPage(gardenId: gardenId),
                          ),
                        ),
                      ),
                    ).whenComplete(() {
                      // Si le mode n'est pas addPlant, c'est que l'utilisateur a quitté avant de finir
                      final mode = ref.read(mapModeProvider);
                      if (mode != MapMode.addPlant) {
                        ref.read(addPlantProvider.notifier).state =
                            const AddPlantState();
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
