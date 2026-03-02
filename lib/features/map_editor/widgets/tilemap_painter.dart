import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';

Map<int, Rect> generateAutoTileRects({
  required int tilePixelSize,
  required int columns,
  required int startIndex,
  required String tileType, // "soil" ou "hard"
}) {
  final map = <int, Rect>{};

  for (int mask = 0; mask < 16; mask++) {
    // 🔹 utiliser ton mapping
    final mappedMask = tileType == "soil"
        ? soilMaskToIndex[mask]!
        : hardMaskToIndex[mask]!;

    final index = startIndex + mappedMask;

    final row = index ~/ columns;
    final col = index % columns;

    map[mask] = Rect.fromLTWH(
      col * tilePixelSize.toDouble(),
      row * tilePixelSize.toDouble(),
      tilePixelSize.toDouble(),
      tilePixelSize.toDouble(),
    );
  }

  return map;
}

const Map<int, int> soilMaskToIndex = {
  0: 33,
  1: 23,
  2: 30,
  3: 20,
  4: 3,
  5: 13,
  6: 0,
  7: 10,
  8: 32,
  9: 22,
  10: 31,
  11: 21,
  12: 2,
  13: 12,
  14: 1,
  15: 11,
};

const Map<int, int> hardMaskToIndex = {
  0: 19,
  1: 11,
  2: 16,
  3: 8,
  4: 3,
  5: 7,
  6: 0,
  7: 4,
  8: 18,
  9: 10,
  10: 17,
  11: 9,
  12: 2,
  13: 6,
  14: 1,
  15: 5,
};

class GardenPainter extends CustomPainter {
  final List<List<TileType>> tiles;
  final double tileSize;
  final Offset? selectionStart;
  final Offset? selectionEnd;

  final ui.Image soilImage;
  final ui.Image hardImage;

  final Map<int, Rect> soilRects;
  final Map<int, Rect> hardRects;

  final int tilesWide;
  final int tilesHigh;

  final Rect visibleRect;
  final ui.Image? backgroundCache;

  final Size viewportSize;
  final Offset Function(Offset) screenToWorld;

  GardenPainter({
    required this.tiles,
    required this.tileSize,
    this.selectionStart,
    this.selectionEnd,
    required this.soilImage,
    required this.hardImage,
    required this.soilRects,
    required this.hardRects,
    required this.tilesWide,
    required this.tilesHigh,
    required this.visibleRect,
    required this.backgroundCache,
    required this.viewportSize,
    required this.screenToWorld,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ---- Fond (cache)
    if (backgroundCache != null) {
      canvas.drawImage(backgroundCache!, Offset.zero, Paint());
    } else {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const ui.Color.fromARGB(255, 228, 123, 88),
      );
    }

    // ---- Culling
    final corners = [
      Offset(0, 0),
      Offset(viewportSize.width, 0),
      Offset(0, viewportSize.height),
      Offset(viewportSize.width, viewportSize.height),
    ];

    // Convertir les coins écran → monde
    final worldCorners = corners.map(screenToWorld).toList();

    // Trouver les min/max X et Y
    final minX = worldCorners.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final maxX = worldCorners.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final minY = worldCorners.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxY = worldCorners.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    final startX = (minX / tileSize).floor().clamp(0, tilesWide - 1);
    final endX = (maxX / tileSize).ceil().clamp(0, tilesWide - 1);
    final startY = (minY / tileSize).floor().clamp(0, tilesHigh - 1);
    final endY = (maxY / tileSize).ceil().clamp(0, tilesHigh - 1);

    // ---- Tiles dynamiques
    for (int y = startY; y <= endY; y++) {
      for (int x = startX; x <= endX; x++) {
        final t = tiles[y][x];

        if (t == TileType.empty) continue;

        final mask = computeMask(x, y);

        final rectMap = t == TileType.soil ? soilRects : hardRects;
        final image = t == TileType.soil ? soilImage : hardImage;

        final srcRect = rectMap[mask]!;

        final dstRect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        canvas.drawImageRect(image, srcRect, dstRect, Paint());
      }
    }

    // ---- Sélection
    if (selectionStart != null && selectionEnd != null) {
      final paint = Paint()..color = Colors.blue.withOpacity(0.3);

      final sx = (selectionStart!.dx / tileSize).floor();
      final sy = (selectionStart!.dy / tileSize).floor();
      final ex = (selectionEnd!.dx / tileSize).floor();
      final ey = (selectionEnd!.dy / tileSize).floor();

      final left = sx < ex ? sx : ex;
      final right = sx > ex ? sx : ex;
      final top = sy < ey ? sy : ey;
      final bottom = sy > ey ? sy : ey;

      for (int y = top; y <= bottom; y++) {
        for (int x = left; x <= right; x++) {
          canvas.drawRect(
            Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
            paint,
          );
        }
      }
    }
  }

  int computeMask(int x, int y) {
    final width = tiles[0].length;
    final height = tiles.length;
    final type = tiles[y][x];

    int mask = 0;

    // N
    if (y > 0 && tiles[y - 1][x] == type) mask |= 1;

    // E
    if (x < width - 1 && tiles[y][x + 1] == type) mask |= 2;

    // S
    if (y < height - 1 && tiles[y + 1][x] == type) mask |= 4;

    // W
    if (x > 0 && tiles[y][x - 1] == type) mask |= 8;

    return mask;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
