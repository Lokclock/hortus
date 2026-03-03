import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapTransformProvider = Provider<TransformationController>((ref) {
  return TransformationController();
});

class MapTransformState {
  final Offset translation;
  final double scale;
  final double rotation;

  const MapTransformState({
    required this.translation,
    required this.scale,
    required this.rotation,
  });

  factory MapTransformState.initial() =>
      const MapTransformState(translation: Offset.zero, scale: 1, rotation: 0);

  MapTransformState copyWith({
    Offset? translation,
    double? scale,
    double? rotation,
  }) {
    return MapTransformState(
      translation: translation ?? this.translation,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class MapTransformNotifier extends StateNotifier<MapTransformState> {
  MapTransformNotifier() : super(MapTransformState.initial());

  void update({Offset? translation, double? scale, double? rotation}) {
    state = state.copyWith(
      translation: translation,
      scale: scale,
      rotation: rotation,
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
