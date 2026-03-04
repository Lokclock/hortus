import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapTransformProvider = Provider<TransformationController>((ref) {
  return TransformationController();
});

class MapTransformState {
  final Offset translation;
  final double scale;
  final double rotation;
  final Size viewportSize;

  const MapTransformState({
    required this.translation,
    required this.scale,
    required this.rotation,
    required this.viewportSize,
  });

  factory MapTransformState.initial() => const MapTransformState(
    translation: Offset.zero,
    scale: 1,
    rotation: 0,
    viewportSize: Size.zero,
  );

  MapTransformState copyWith({
    Offset? translation,
    double? scale,
    double? rotation,
    Size? viewportSize,
  }) {
    return MapTransformState(
      translation: translation ?? this.translation,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      viewportSize: viewportSize ?? this.viewportSize,
    );
  }

  /// 🔥 MATRICE IDENTIQUE à GardenCanvas
  Matrix4 get matrix {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

    return Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(rotation)
      ..scale(scale)
      ..translate(-center.dx + translation.dx, -center.dy + translation.dy);
  }

  /// 🌍 écran → monde (100% fiable)
  Offset screenToWorld(Offset screenPoint) {
    final inv = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inv, screenPoint);
  }

  /// 🔄 monde → écran
  Offset worldToScreen(Offset worldPoint) {
    return MatrixUtils.transformPoint(matrix, worldPoint);
  }
}

class MapTransformNotifier extends StateNotifier<MapTransformState> {
  MapTransformNotifier() : super(MapTransformState.initial());

  void update({
    Offset? translation,
    double? scale,
    double? rotation,
    Size? viewportSize,
  }) {
    state = state.copyWith(
      translation: translation,
      scale: scale,
      rotation: rotation,
      viewportSize: viewportSize,
    );
  }

  void reset() {
    state = MapTransformState.initial();
  }
}

final mapTransformProviderNotifier =
    StateNotifierProvider<MapTransformNotifier, MapTransformState>(
      (ref) => MapTransformNotifier(),
    );
