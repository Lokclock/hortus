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

  GardenPainter({
    required this.tiles,
    required this.tileSize,
    this.selectionStart,
    this.selectionEnd,
    required this.soilImage,
    required this.hardImage,
    required this.soilRects,
    required this.hardRects,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fond bleu sur tout l'écran
    final sizePlus = Size(size.width + 10000, size.height + 10000);
    final rectBackgroundPaint = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    canvas.drawRect(Offset(-5000, -5000) & sizePlus, rectBackgroundPaint);

    // Rectangle du jardin (jaune)
    final rectPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    canvas.drawRect(Offset.zero & size, rectPaint);

    // Quadrillage
    final gridPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke;
    for (double x = 0; x <= size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Dessiner les tiles existantes
    for (int y = 0; y < tiles.length; y++) {
      for (int x = 0; x < tiles[y].length; x++) {
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
    if (selectionStart != null && selectionEnd != null) {
      // Convertir en indices de tiles
      int startX = (selectionStart!.dx / tileSize).floor();
      int startY = (selectionStart!.dy / tileSize).floor();
      int endX = (selectionEnd!.dx / tileSize).floor();
      int endY = (selectionEnd!.dy / tileSize).floor();

      // 🔹 Clipper aux limites du tableau
      startX = startX.clamp(0, tiles[0].length - 1);
      endX = endX.clamp(0, tiles[0].length - 1);
      startY = startY.clamp(0, tiles.length - 1);
      endY = endY.clamp(0, tiles.length - 1);

      final left = startX < endX ? startX : endX;
      final right = startX > endX ? startX : endX;
      final top = startY < endY ? startY : endY;
      final bottom = startY > endY ? startY : endY;

      final paint = Paint()..color = Colors.blue.withOpacity(0.3);

      // Boucler seulement sur les tiles valides
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
