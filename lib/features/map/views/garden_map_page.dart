import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/garden_permissions_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';
import 'package:hortus_app/features/map/views/add_plant_page.dart';
import 'package:hortus_app/features/map/views/garden_canvas.dart';
import 'package:hortus_app/features/map/views/positioning_overlay.dart';
import 'package:hortus_app/features/map/views/show_plants_list.dart';
import '../../plants/providers/plant_providers.dart';

class GardenMapPage extends ConsumerWidget {
  final String gardenId;

  const GardenMapPage({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(mapModeProvider);
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

          /// 🔻 FLOATING BOTTOM BAR
          mode != MapMode.addPlant
              ? _BottomMapBar(canEdit: canEdit, gardenId: gardenId)
              : const SizedBox(),

          PositioningOverlay(gardenId: gardenId),

          /// 🔝 MINI TOP BAR
          mode != MapMode.addPlant
              ? _TopMapBar(gardenId: gardenId)
              : const SizedBox(),
        ],
      ),
    );
  }
}

class _TopMapBar extends ConsumerWidget {
  final String gardenId;

  const _TopMapBar({required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(gardenProvider(gardenId));

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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.push('/home'),
              ),

              const SizedBox(width: 8),

              /// 👇 NOM CLIQUABLE
              Expanded(
                child: gardenAsync.when(
                  loading: () => const Text("..."),
                  error: (_, __) => const Text("Erreur"),
                  data: (garden) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.push('/garden-details/${garden.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        garden.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
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
    final theme = Theme.of(context);

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
              IconButton(
                icon: Icon(
                  Icons.filter_none_rounded,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  // ouvrir profil bottom sheet
                },
              ),
              const SizedBox(width: 24),
              if (canEdit)
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors
                          .transparent, // permet de voir le handle proprement
                      builder: (_) => SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.8,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 🔹 HANDLE DRAG
                                  Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),

                                  // 🔹 CONTENU EXISTANT
                                  Expanded(
                                    child: AddPlantPage(gardenId: gardenId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).whenComplete(() {
                      final mode = ref.read(mapModeProvider);
                      if (mode != MapMode.addPlant) {
                        ref.read(addPlantProvider.notifier).state =
                            const AddPlantState();
                      }
                    });
                  },
                ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(
                  Icons.list,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  showPlantsList(context, ref, gardenId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
