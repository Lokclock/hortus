import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/utils/map_math.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';
import 'package:hortus_app/features/map/providers/animated_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/views/plant_details/details/plant_details_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

enum MapGestureMode { unknown, pinch, rotate }

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
  ConsumerState<GardenCanvas> createState() => GardenCanvasState();
}

class GardenCanvasState extends ConsumerState<GardenCanvas> {
  Offset startTranslation = Offset.zero;
  double startScale = 1.0;
  double startRotation = 0.0;
  Offset startFocal = Offset.zero;
  Offset lastFocalPoint = Offset.zero;

  MapGestureMode gestureMode = MapGestureMode.unknown;

  double zoomThreshold = 0.02;
  double rotationThreshold = 0.1;

  double scale = 1.0;
  double rotation = 0.0;
  Offset translation = Offset.zero;

  Matrix4 _transform = Matrix4.identity();

  Size _viewportSize = Size.zero;

  Size? mapWorldSize;
  Size? _lastInitViewport;

  _updateTransform() {
    final center = Vector3(
      _viewportSize.width / 2,
      _viewportSize.height / 2,
      0,
    );
    setState(() {
      _transform = Matrix4.identity()
        ..translate(center.x, center.y)
        ..rotateZ(rotation)
        ..scale(scale)
        ..translate(-center.x + translation.dx, -center.y + translation.dy);
    });
  }

  Offset _clampTranslation(Offset candidate, Size mapWorldSize) {
    const double allowedOverflow = 80.0;

    final testTransform = Matrix4.identity()
      ..translate(_viewportSize.width / 2, _viewportSize.height / 2)
      ..scale(scale)
      ..rotateZ(rotation)
      ..translate(
        -_viewportSize.width / 2 + candidate.dx,
        -_viewportSize.height / 2 + candidate.dy,
      );

    // Transforme les 4 coins
    final corners = [
      MatrixUtils.transformPoint(testTransform, const Offset(0, 0)),
      MatrixUtils.transformPoint(testTransform, Offset(mapWorldSize.width, 0)),
      MatrixUtils.transformPoint(
        testTransform,
        Offset(mapWorldSize.width, mapWorldSize.height),
      ),
      MatrixUtils.transformPoint(testTransform, Offset(0, mapWorldSize.height)),
    ];

    final minX = corners.map((p) => p.dx).reduce(math.min);
    final maxX = corners.map((p) => p.dx).reduce(math.max);
    final minY = corners.map((p) => p.dy).reduce(math.min);
    final maxY = corners.map((p) => p.dy).reduce(math.max);

    double correctionX = 0;
    double correctionY = 0;

    // ---- X axis ----
    if (maxX < allowedOverflow) {
      correctionX = allowedOverflow - maxX;
    } else if (minX > _viewportSize.width - allowedOverflow) {
      correctionX = (_viewportSize.width - allowedOverflow) - minX;
    }

    // ---- Y axis ----
    if (maxY < allowedOverflow) {
      correctionY = allowedOverflow - maxY;
    } else if (minY > _viewportSize.height - allowedOverflow) {
      correctionY = (_viewportSize.height - allowedOverflow) - minY;
    }

    final inv = Matrix4.inverted(testTransform);
    final worldDelta =
        MatrixUtils.transformPoint(inv, Offset(correctionX, correctionY)) -
        MatrixUtils.transformPoint(inv, Offset.zero);

    return candidate + worldDelta;
  }

  Offset _screenToWorld(Offset screenPos) {
    final inv = Matrix4.inverted(_transform);
    return MatrixUtils.transformPoint(inv, screenPos);
  }

  Offset _screenDeltaToWorld(Offset delta) {
    // Convertir déplacement écran en déplacement monde
    final scaled = delta / scale;
    final cosR = math.cos(-rotation);
    final sinR = math.sin(-rotation);
    return Offset(
      scaled.dx * cosR - scaled.dy * sinR,
      scaled.dx * sinR + scaled.dy * cosR,
    );
  }

  _onScaleUpdate(ScaleUpdateDetails details) {
    if (mapWorldSize == null) return;

    // 1️⃣ Détecter le geste dominant
    final scaleDelta = (details.scale - 1.0).abs();
    final rotationDelta = details.rotation.abs();

    if (gestureMode == MapGestureMode.unknown) {
      if (scaleDelta > zoomThreshold && details.pointerCount >= 2) {
        gestureMode = MapGestureMode.pinch;
      } else if (rotationDelta > rotationThreshold &&
          details.pointerCount >= 2) {
        gestureMode = MapGestureMode.rotate;
      }
    }

    // 2️⃣ Coordonnée monde du point focal avant changement
    final focalWorldBefore = _screenToWorld(details.focalPoint);

    // 3️⃣ Appliquer scale/rotation

    if (gestureMode == MapGestureMode.pinch ||
        gestureMode == MapGestureMode.rotate) {
      scale = (startScale * details.scale).clamp(0.04, 2.0);
    }
    if (gestureMode == MapGestureMode.rotate) {
      rotation = startRotation + details.rotation;
    }

    // 4️⃣ Coordonnée monde du point focal après changement
    final focalWorldAfter = _screenToWorld(details.focalPoint);

    // Ajuster translation pour que le point focal reste sous les doigts
    translation += (focalWorldBefore - focalWorldAfter);

    // 5️⃣ Pan libre
    final deltaScreen = details.focalPoint - lastFocalPoint;
    final deltaWorld = _screenDeltaToWorld(deltaScreen);
    translation += deltaWorld;

    // 6️⃣ Clamp final
    translation = _clampTranslation(translation, mapWorldSize!);

    lastFocalPoint = details.focalPoint;

    // Mettre à jour le transform et notifier le provider
    _updateTransform();
    ref
        .read(mapTransformProviderNotifier.notifier)
        .update(
          translation: translation,
          scale: scale,
          rotation: rotation,
          viewportSize: _viewportSize,
        );
  }

  _onScaleStart(ScaleStartDetails details) {
    startTranslation = translation;
    startScale = scale;
    startRotation = rotation;
    lastFocalPoint = details.focalPoint;
    gestureMode = MapGestureMode.unknown;
  }

  _onScaleEnd(ScaleEndDetails details) {
    gestureMode = MapGestureMode.unknown;
  }

  void resetViewToFit(Size mapWorldSize, {double margin = 40.0}) {
    final viewW = _viewportSize.width;
    final viewH = _viewportSize.height;

    final scaleX = (viewW - 2 * margin) / mapWorldSize.width;
    final scaleY = (viewH - 2 * margin) / mapWorldSize.height;
    scale = math.min(scaleX, scaleY);
    rotation = 0.0;

    final worldCenter = Offset(mapWorldSize.width / 2, mapWorldSize.height / 2);
    final viewportCenter = Offset(viewW / 2, viewH / 2);

    translation = viewportCenter - worldCenter;

    _updateTransform();

    ref
        .read(mapTransformProviderNotifier.notifier)
        .update(
          translation: translation,
          scale: scale,
          rotation: rotation,
          viewportSize: _viewportSize,
        );
  }

  @override
  Widget build(BuildContext context) {
    final gardenAsync = ref.watch(gardenProvider(widget.gardenId));

    return gardenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Erreur: $e")),
      data: (garden) {
        // ✅ calculer mapWorldSize
        mapWorldSize = Size(
          (garden.tilesWide ?? 0) * (garden.tileSize ?? 1),
          (garden.tilesHigh ?? 0) * (garden.tileSize ?? 1),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            _viewportSize = constraints.biggest;

            // ✅ Vérifie qu'on a une map et un viewport valide
            if (mapWorldSize != null &&
                _viewportSize.isFinite &&
                _viewportSize != Size.zero &&
                _lastInitViewport != _viewportSize) {
              _lastInitViewport = _viewportSize;

              // 🔹 Fit après le build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                resetViewToFit(
                  mapWorldSize!,
                  margin: 20.0,
                ); // marge paramétrable

                // 🔹 Si tu veux que l'UI soit mise à jour
                setState(() {});
              });
            }

            return Container(
              color: const ui.Color.fromARGB(162, 159, 212, 255),
              child: GestureDetector(
                onTapDown: (details) {
                  final worldPos = _screenToWorld(details.localPosition);

                  for (final p in widget.plants) {
                    final plantPos = Offset(p.x, p.y);
                    final radius = p.diameter / 1.2;
                    if ((worldPos - plantPos).distance <= radius) {
                      ref.read(animatedPlantProvider.notifier).state = p.id;

                      Future.delayed(const Duration(milliseconds: 220), () {
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
                      });

                      Future.delayed(const Duration(milliseconds: 400), () {
                        ref.read(animatedPlantProvider.notifier).state = null;
                      });

                      break; // Stop après la première plante tapée
                    }
                  }
                },
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  _onScaleStart(details);
                },
                onScaleUpdate: (details) {
                  _onScaleUpdate(details);
                },
                onScaleEnd: (details) {
                  _onScaleEnd(details);
                },
                child: Transform(
                  transform: _transform,
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Map
                        widget.tilemapImage != null
                            ? RawImage(image: widget.tilemapImage)
                            : const SizedBox.shrink(),

                        // 🌱 Plants
                        ...widget.plants.map((p) {
                          final worldPos = Offset(p.x, p.y);

                          final diameterPx = p.diameter * (64 / 20);

                          final animatedId = ref.watch(animatedPlantProvider);
                          final isAnimated = animatedId == p.id;

                          return Positioned(
                            left: worldPos.dx - diameterPx / 2,
                            top: worldPos.dy - diameterPx / 2,
                            child: SizedBox(
                              width: diameterPx,
                              height: diameterPx,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 1,
                                  end: isAnimated ? 1.25 : 1,
                                ),
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
                                        width: diameterPx,
                                        height: diameterPx,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.local_florist,
                                        color: Colors.green,
                                        size: p.diameter,
                                      ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
