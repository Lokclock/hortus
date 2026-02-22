import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TileType { empty, soil, hard }

class TileEditorState {
  final List<List<TileType>> tiles;
  final TileType currentBrush;

  TileEditorState({required this.tiles, this.currentBrush = TileType.soil});

  TileEditorState copyWith({
    List<List<TileType>>? tiles,
    TileType? currentBrush,
  }) {
    return TileEditorState(
      tiles: tiles ?? this.tiles,
      currentBrush: currentBrush ?? this.currentBrush,
    );
  }
}

class TileEditorNotifier extends StateNotifier<TileEditorState> {
  TileEditorNotifier(int width, int height)
    : super(
        TileEditorState(
          tiles: List.generate(
            height,
            (_) => List.generate(width, (_) => TileType.empty),
          ),
        ),
      );

  void setBrush(TileType brush) {
    state = state.copyWith(currentBrush: brush);
  }

  void updateTiles(List<List<TileType>> newTiles) {
    state = state.copyWith(tiles: newTiles);
  }
}

final tileEditorProvider =
    StateNotifierProvider.family<TileEditorNotifier, TileEditorState, Size>((
      ref,
      size,
    ) {
      final width = (size.width).toInt();
      final height = (size.height).toInt();
      return TileEditorNotifier(width > 0 ? width : 1, height > 0 ? height : 1);
    });
