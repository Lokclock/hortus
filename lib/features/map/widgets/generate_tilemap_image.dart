import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hortus_app/features/map/providers/tilemap_provider.dart';

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

Future<ui.Image> generateTilemapImage(
  List<List<TileType>> tiles,
  double tileSize,
  ui.Image soilImage,
  ui.Image hardImage,
) async {
  final tilesHigh = tiles.length;
  final tilesWide = tiles[0].length;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  // ---- 1️⃣ Dessiner le fond uniquement (coins, bords, centre)
  for (int y = 0; y < tilesHigh; y++) {
    for (int x = 0; x < tilesWide; x++) {
      final isTop = y == 0;
      final isBottom = y == tilesHigh - 1;
      final isLeft = x == 0;
      final isRight = x == tilesWide - 1;

      int index;
      if (isTop && isLeft)
        index = 5;
      else if (isTop && isRight)
        index = 7;
      else if (isBottom && isLeft)
        index = 25;
      else if (isBottom && isRight)
        index = 27;
      else if (isTop)
        index = 6;
      else if (isBottom)
        index = 26;
      else if (isLeft)
        index = 15;
      else if (isRight)
        index = 17;
      else
        index = 16;

      final srcRect = Rect.fromLTWH(
        (index % 10) * 64,
        (index ~/ 10) * 64,
        64,
        64,
      );

      canvas.drawImageRect(
        soilImage, // toujours soilImage pour le fond
        srcRect,
        Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
        paint,
      );
    }
  }

  for (int y = 0; y < tilesHigh; y++) {
    for (int x = 0; x < tilesWide; x++) {
      final t = tiles[y][x];
      if (t == TileType.empty) continue;

      // ---- Calculer mask
      final mask = computeMask(x, y, tiles);

      final double tileSize = 64; // taille de la tuile sur le canvas
      final int tilePixelSize = 64;
      final int soilColumns = 10;
      final int hardColumns = 4;

      // ---- Choisir spritesheet et mapping
      final image = t == TileType.soil ? soilImage : hardImage;
      final indexMap = t == TileType.soil ? soilMaskToIndex : hardMaskToIndex;
      final columns = t == TileType.soil ? soilColumns : hardColumns;

      final tileIndex = indexMap[mask]!;
      final row = tileIndex ~/ columns;
      final col = tileIndex % columns;

      final srcRect = Rect.fromLTWH(
        col * tilePixelSize.toDouble(),
        row * tilePixelSize.toDouble(),
        tilePixelSize.toDouble(),
        tilePixelSize.toDouble(),
      );

      final dstRect = Rect.fromLTWH(
        x * tileSize,
        y * tileSize,
        tileSize,
        tileSize,
      );

      canvas.drawImageRect(image, srcRect, dstRect, paint);
    }
  }

  final picture = recorder.endRecording();
  return picture.toImage(
    (tilesWide * tileSize).ceil(),
    (tilesHigh * tileSize).ceil(),
  );
}

// Fonction pour calculer le mask
int computeMask(int x, int y, List<List<TileType>> tiles) {
  final width = tiles[0].length;
  final height = tiles.length;
  final type = tiles[y][x];

  int mask = 0;

  if (y > 0 && tiles[y - 1][x] == type) mask |= 1; // N
  if (x < width - 1 && tiles[y][x + 1] == type) mask |= 2; // E
  if (y < height - 1 && tiles[y + 1][x] == type) mask |= 4; // S
  if (x > 0 && tiles[y][x - 1] == type) mask |= 8; // W

  return mask;
}
