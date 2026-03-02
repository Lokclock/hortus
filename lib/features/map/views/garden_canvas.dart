import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/animated_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/views/plant_details_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class GardenCanvas extends ConsumerWidget {
  final String gardenId;
  final List<Plant> plants;
  final bool canEdit;
  final ui.Image? tilemapImage;

  const GardenCanvas({
    super.key,
    required this.gardenId,
    required this.plants,
    required this.canEdit,
    required this.tilemapImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transformController = ref.watch(mapTransformProvider);

    return InteractiveViewer(
      transformationController: transformController,
      maxScale: 4,
      minScale: 0.5,
      child: Container(
        width: 2000,
        height: 2000,
        color: Colors.green.shade50,
        child: Stack(
          children: [
            // 🌱 Fond tilemap
            if (tilemapImage != null)
              Positioned.fill(
                child: RawImage(image: tilemapImage, fit: BoxFit.cover),
              ),
            ...plants.map((p) {
              final diameter = p.diameter;
              final animatedId = ref.watch(animatedPlantProvider);
              final isAnimated = animatedId == p.id;

              return Positioned(
                left: p.x - diameter / 2,
                top: p.y - diameter / 2,
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      /// 🌿 IMAGE AVEC ANIMATION SCALE
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1, end: isAnimated ? 1.25 : 1),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: (p.symbol.isNotEmpty)
                            ? Image.asset(
                                p.symbol,
                                width: diameter,
                                height: diameter,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.local_florist,
                                color: Colors.green,
                                size: diameter,
                              ),
                      ),

                      /// 🔴 ZONE TAPPABLE
                      GestureDetector(
                        onTap: () {
                          if (!canEdit) return;

                          /// 1️⃣ déclenche animation
                          ref.read(animatedPlantProvider.notifier).state = p.id;

                          /// 2️⃣ ouvre la fiche APRÈS un petit délai
                          Future.delayed(const Duration(milliseconds: 220), () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => PlantDetailsSheet(
                                plantId: p.id,
                                gardenId: gardenId,
                                canEdit: canEdit,
                              ),
                            );
                          });

                          /// 3️⃣ reset animation
                          Future.delayed(const Duration(milliseconds: 400), () {
                            ref.read(animatedPlantProvider.notifier).state =
                                null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
