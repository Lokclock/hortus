import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tilemap_model.dart';

class TileEditorState {
  final TileMapData map;
  final int selectedSprite;
  final TileType selectedType;
  final bool isPainting;
  final int? lastPaintedIndex;

  TileEditorState({
    required this.map,
    required this.selectedSprite,
    required this.selectedType,
    required this.isPainting,
    this.lastPaintedIndex,
  });

  TileEditorState copyWith({
    TileMapData? map,
    int? selectedSprite,
    TileType? selectedType,
    bool? isPainting,
    int? lastPaintedIndex,
  }) {
    return TileEditorState(
      map: map ?? this.map,
      selectedSprite: selectedSprite ?? this.selectedSprite,
      selectedType: selectedType ?? this.selectedType,
      isPainting: isPainting ?? this.isPainting,
      lastPaintedIndex: lastPaintedIndex,
    );
  }
}

class TileEditorNotifier extends StateNotifier<TileEditorState> {
  TileEditorNotifier()
    : super(
        TileEditorState(
          map: TileMapData.empty(50, 50, 32),
          selectedSprite: 1,
          selectedType: TileType.soil,
          isPainting: false,
        ),
      );

  void startPainting() {
    state = state.copyWith(isPainting: true);
  }

  void stopPainting() {
    state = state.copyWith(isPainting: false, lastPaintedIndex: null);
  }

  void paintTile(int row, int col) {
    final index = state.map.index(row, col);

    if (index == state.lastPaintedIndex) return;

    state.map.setTile(row, col, state.selectedSprite, state.selectedType);

    state = state.copyWith(lastPaintedIndex: index);
  }

  void selectTile(int sprite, TileType type) {
    state = state.copyWith(selectedSprite: sprite, selectedType: type);
  }
}

final tileEditorProvider =
    StateNotifierProvider<TileEditorNotifier, TileEditorState>(
      (ref) => TileEditorNotifier(),
    );
