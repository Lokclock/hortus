import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/animated_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/views/plant_details_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

enum _MapGestureMode { unknown, pinch, rotate }

class GardenCanvas extends ConsumerStatefulWidget {
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
  ConsumerState<GardenCanvas> createState() => _GardenCanvasState();
}

class _GardenCanvasState extends ConsumerState<GardenCanvas> {
  Offset offset = Offset.zero;
  double scale = 1.0;
  double rotation = 0.0;
  Offset startOffset = Offset.zero;
  double startScale = 1.0;
  double startRotation = 0.0;
  Offset lastFocalPoint = Offset.zero;
  final double _zoomThreshold = 0.02;
  final double _rotationThreshold = 0.02;
  _MapGestureMode _mapGestureMode = _MapGestureMode.unknown;
  Offset translation = Offset.zero;
  Size _viewportSize = Size.zero;
  Matrix4 _transform = Matrix4.identity();

  Offset _screenDeltaToWorld(Offset delta) {
    // Enlever le scale
    final scaled = delta / scale;

    // Enlever la rotation
    final cosR = math.cos(-rotation);
    final sinR = math.sin(-rotation);

    return Offset(
      scaled.dx * cosR - scaled.dy * sinR,
      scaled.dx * sinR + scaled.dy * cosR,
    );
  }

  void resetViewToFit(Size mapWorldSize) {
    final mapW = mapWorldSize.width;
    final mapH = mapWorldSize.height;

    final viewW = _viewportSize.width;
    final viewH = _viewportSize.height;

    // 0️⃣ Reset propre
    scale = 1.0;
    rotation = 0.0;
    translation = Offset.zero;

    // 1️⃣ Rotation (grand axe vertical)
    if (mapW > mapH) {
      rotation = math.pi / 2;
    }

    // 2️⃣ Dimensions apparentes après rotation
    final fittedW = rotation == 0 ? mapW : mapH;
    final fittedH = rotation == 0 ? mapH : mapW;

    // 3️⃣ Scale FIT (⚠️ division, pas multiplication)
    scale = (math.max(fittedW / viewW, fittedH / viewH)) * 1.05;

    // 4️⃣ Centrage monde → viewport
    final worldCenter = Offset(mapW / 2, mapH / 2);
    final viewportCenter = Offset(viewW / 2, viewH / 2);

    translation = viewportCenter - worldCenter;

    _updateTransform();
  }

  void _updateTransform() {
    // On veut que le zoom se fasse autour du centre du viewport
    final center = Vector3(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
      0,
    );

    _transform = Matrix4.identity()
      ..translateByVector3(center) // on déplace le centre au milieu
      ..scaleByDouble(1.0, 1.0, 1.0, scale) // on applique le zoom
      ..rotateZ(rotation) // rotation si besoin
      ..translateByVector3(
        Vector3(-center.x + translation.dx, -center.y + translation.dy, 0),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade200,
      child: GestureDetector(
        onScaleStart: (details) {
          lastFocalPoint = details.focalPoint;
          startOffset = offset;
          startScale = scale;
          startRotation = rotation;
          _mapGestureMode = _MapGestureMode.unknown;
        },
        onScaleUpdate: (details) {
          setState(() {
            final scaleDelta = (details.scale - 1.0).abs();
            final rotationDelta = details.rotation.abs();

            // Déterminer le geste dominant
            if (scaleDelta > _zoomThreshold) {
              _mapGestureMode = _MapGestureMode.pinch;
            } else if (rotationDelta > _rotationThreshold &&
                details.pointerCount >= 2) {
              _mapGestureMode = _MapGestureMode.rotate;
            }

            // Translation toujours appliquée
            final deltaScreen =
                (details.focalPoint - lastFocalPoint) * scale * scale;
            final deltaWorld = _screenDeltaToWorld(deltaScreen);
            offset = startOffset + deltaWorld;
            // Appliquer scale seulement si geste dominant est pinch ou rotate
            if (_mapGestureMode == _MapGestureMode.pinch ||
                _mapGestureMode == _MapGestureMode.rotate) {
              scale = startScale * details.scale;
            }

            // Appliquer rotation seulement si geste dominant est rotate
            if (_mapGestureMode == _MapGestureMode.rotate) {
              rotation = startRotation + details.rotation;
            }
          });
        },
        onScaleEnd: (details) {
          _mapGestureMode = _MapGestureMode.unknown;
        },
        child: Center(
          child: Transform(
            alignment: Alignment.center,
            transform: _transform,
            child: Stack(
              children: [
                // 🌱 Fond tilemap
                if (widget.tilemapImage != null)
                  RawImage(image: widget.tilemapImage),

                // 🌱 Plants
                ...widget.plants.map((p) {
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
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
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
                              if (!widget.canEdit) return;

                              /// 1️⃣ déclenche animation
                              ref.read(animatedPlantProvider.notifier).state =
                                  p.id;

                              /// 2️⃣ ouvre la fiche APRÈS un petit délai
                              Future.delayed(
                                const Duration(milliseconds: 220),
                                () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => PlantDetailsSheet(
                                      plantId: p.id,
                                      gardenId: widget.gardenId,
                                      canEdit: widget.canEdit,
                                    ),
                                  );
                                },
                              );

                              /// 3️⃣ reset animation
                              Future.delayed(
                                const Duration(milliseconds: 400),
                                () {
                                  ref
                                          .read(animatedPlantProvider.notifier)
                                          .state =
                                      null;
                                },
                              );
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
        ),
      ),
    );
  }
}
