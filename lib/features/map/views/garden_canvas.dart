import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';
import 'package:hortus_app/features/map/providers/animated_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_transform_provider.dart';
import 'package:hortus_app/features/map/views/plant_details_sheet.dart';
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
  ConsumerState<GardenCanvas> createState() => _GardenCanvasState();
}

class _GardenCanvasState extends ConsumerState<GardenCanvas> {
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
    const double allowedOverflow = 80.0; // 🔥 marge autorisée

    final testTransform = Matrix4.identity()
      ..translate(_viewportSize.width / 2, _viewportSize.height / 2)
      ..scale(scale)
      ..rotateZ(rotation)
      ..translate(
        -_viewportSize.width / 2 + candidate.dx,
        -_viewportSize.height / 2 + candidate.dy,
      );

    // 🔹 Transforme les 4 coins
    final p1 = MatrixUtils.transformPoint(testTransform, const Offset(0, 0));
    final p2 = MatrixUtils.transformPoint(
      testTransform,
      Offset(mapWorldSize.width, 0),
    );
    final p3 = MatrixUtils.transformPoint(
      testTransform,
      Offset(mapWorldSize.width, mapWorldSize.height),
    );
    final p4 = MatrixUtils.transformPoint(
      testTransform,
      Offset(0, mapWorldSize.height),
    );

    final minX = [p1.dx, p2.dx, p3.dx, p4.dx].reduce(math.min);
    final maxX = [p1.dx, p2.dx, p3.dx, p4.dx].reduce(math.max);
    final minY = [p1.dy, p2.dy, p3.dy, p4.dy].reduce(math.min);
    final maxY = [p1.dy, p2.dy, p3.dy, p4.dy].reduce(math.max);

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

    // Point écran fictif corrigé
    final correctedScreen = Offset(correctionX, correctionY);

    // Convertir delta écran → delta monde
    final worldDelta =
        MatrixUtils.transformPoint(inv, correctedScreen) -
        MatrixUtils.transformPoint(inv, Offset.zero);
    debugPrint("""
--- CLAMP ---
minX: $minX
maxX: $maxX
minY: $minY
maxY: $maxY
viewport: $_viewportSize
candidate: $candidate
correctionX: $correctionX
correctionY: $correctionY
""");
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
      scale = (startScale * details.scale).clamp(0.2, 8.0);
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
        .update(translation: translation, scale: scale, rotation: rotation);
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

  resetMapTransform() {
    setState(() {
      scale = 1.0;
      rotation = 0.0;
      translation = Offset.zero;
      _updateTransform();
      ref.read(mapTransformProviderNotifier.notifier).reset();
    });
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
            _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
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
                child: Stack(
                  children: [
                    // 🌱 Fond tilemap
                    if (widget.tilemapImage != null)
                      SizedBox(
                        width: mapWorldSize?.width ?? _viewportSize.width,
                        height: mapWorldSize?.height ?? _viewportSize.height,
                        child: RawImage(image: widget.tilemapImage),
                      ),

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
                                  ref
                                          .read(animatedPlantProvider.notifier)
                                          .state =
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
                                              .read(
                                                animatedPlantProvider.notifier,
                                              )
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
                    CustomPaint(
                      size: _viewportSize,
                      painter: DebugBoundsPainter(
                        transform: _transform,
                        mapWorldSize: mapWorldSize!,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DebugBoundsPainter extends CustomPainter {
  final Matrix4 transform;
  final Size mapWorldSize;

  DebugBoundsPainter({required this.transform, required this.mapWorldSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paintMap = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final p1 = MatrixUtils.transformPoint(transform, Offset(0, 0));
    final p2 = MatrixUtils.transformPoint(
      transform,
      Offset(mapWorldSize.width, 0),
    );
    final p3 = MatrixUtils.transformPoint(
      transform,
      Offset(mapWorldSize.width, mapWorldSize.height),
    );
    final p4 = MatrixUtils.transformPoint(
      transform,
      Offset(0, mapWorldSize.height),
    );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(path, paintMap);

    // viewport
    final paintViewport = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Offset.zero & size, paintViewport);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
