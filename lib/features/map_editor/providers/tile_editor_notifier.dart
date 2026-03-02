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
  bool _isPainting = false;
  late List<List<TileType>> _paintStartSnapshot;

  TileEditorNotifier(int width, int height)
    : super(
        TileEditorState(
          tiles: List.generate(
            height,
            (_) => List.generate(width, (_) => TileType.empty),
          ),
        ),
      );

  void beginPaint() {
    if (_isPainting) return;

    _isPainting = true;
    _paintStartSnapshot = _clone(state.tiles);
  }

  void endPaint() {
    if (_isPainting) {
      _undoStack.add(TileHistory(_paintStartSnapshot));
      _redoStack.clear();
    }

    _isPainting = false;
    state = state.copyWith(lastPaintPos: null);
  }

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

  void paintRectangle(Offset start, Offset end, double tileSizePx) {
    final width = state.tiles[0].length;
    final height = state.tiles.length;

    int x1 = (start.dx / tileSizePx).floor();
    int y1 = (start.dy / tileSizePx).floor();
    int x2 = (end.dx / tileSizePx).floor();
    int y2 = (end.dy / tileSizePx).floor();

    // 🔹 Clamp pour éviter crash hors grille
    x1 = x1.clamp(0, width - 1);
    x2 = x2.clamp(0, width - 1);
    y1 = y1.clamp(0, height - 1);
    y2 = y2.clamp(0, height - 1);

    final left = x1 < x2 ? x1 : x2;
    final right = x1 > x2 ? x1 : x2;
    final top = y1 < y2 ? y1 : y2;
    final bottom = y1 > y2 ? y1 : y2;

    _pushUndo(); // ⭐ important pour undo

    final newTiles = _clone(state.tiles);

    for (int y = top; y <= bottom; y++) {
      for (int x = left; x <= right; x++) {
        newTiles[y][x] = state.currentBrush;
      }
    }

    state = state.copyWith(tiles: newTiles);
  }

  void reset(int width, int height) {
    state = TileEditorState(
      tiles: List.generate(
        height,
        (_) => List.generate(width, (_) => TileType.empty),
      ),
    );
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
