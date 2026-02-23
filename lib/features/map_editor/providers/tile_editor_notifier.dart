import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TileType { empty, soil, hard }

class TileHistory {
  final List<List<TileType>> tiles;
  TileHistory(this.tiles);
}

class TileEditorState {
  final List<List<TileType>> tiles;
  final TileType currentBrush;
  final Offset? lastPaintPos;

  TileEditorState({
    required this.tiles,
    this.currentBrush = TileType.soil,
    this.lastPaintPos,
  });

  TileEditorState copyWith({
    List<List<TileType>>? tiles,
    TileType? currentBrush,
    Offset? lastPaintPos,
  }) {
    return TileEditorState(
      tiles: tiles ?? this.tiles,
      currentBrush: currentBrush ?? this.currentBrush,
      lastPaintPos: lastPaintPos,
    );
  }
}

class TileEditorNotifier extends StateNotifier<TileEditorState> {
  final List<TileHistory> _undoStack = [];
  final List<TileHistory> _redoStack = [];
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

  void _pushUndo() {
    _undoStack.add(TileHistory(_clone(state.tiles)));
    _redoStack.clear();
  }

  List<List<TileType>> _clone(List<List<TileType>> src) {
    return List.generate(src.length, (y) => List.from(src[y]));
  }

  void paintInterpolated(int x, int y) {
    final last = state.lastPaintPos;

    // Premier point → juste peindre
    if (last == null) {
      paintTile(x, y);
      state = state.copyWith(lastPaintPos: Offset(x.toDouble(), y.toDouble()));
      return;
    }

    int x0 = last.dx.toInt();
    int y0 = last.dy.toInt();

    int dx = (x - x0).abs();
    int dy = (y - y0).abs();

    int sx = x0 < x ? 1 : -1;
    int sy = y0 < y ? 1 : -1;

    int err = dx - dy;

    while (true) {
      paintTile(x0, y0);

      if (x0 == x && y0 == y) break;

      int e2 = 2 * err;

      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }

      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }

    state = state.copyWith(lastPaintPos: Offset(x.toDouble(), y.toDouble()));
  }

  void endPaint() {
    state = state.copyWith(lastPaintPos: null);
  }

  void paintTile(int x, int y) {
    // Sécurité
    if (y < 0 ||
        y >= state.tiles.length ||
        x < 0 ||
        x >= state.tiles[0].length) {
      return;
    }

    // Si déjà peint → ne rien faire (perf)
    if (state.tiles[y][x] == state.currentBrush) return;

    // Copie shallow efficace
    final newTiles = List<List<TileType>>.generate(
      state.tiles.length,
      (i) => List.from(state.tiles[i]),
    );

    newTiles[y][x] = state.currentBrush;

    state = state.copyWith(tiles: newTiles);
  }

  void updateTiles(List<List<TileType>> newTiles) {
    _pushUndo();
    state = state.copyWith(tiles: newTiles);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(TileHistory(_clone(state.tiles)));
    state = state.copyWith(tiles: _undoStack.removeLast().tiles);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(TileHistory(_clone(state.tiles)));
    state = state.copyWith(tiles: _redoStack.removeLast().tiles);
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
