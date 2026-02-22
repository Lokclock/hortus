import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/tilemap_model.dart';
import '../models/zone_model.dart';

class TileMapPainter extends CustomPainter {
  final TileMapData map;
  final List<ui.Image> tileset;
  final List<Zone>? zones;

  TileMapPainter(this.map, this.tileset, {this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 1️⃣ Dessiner le fond avec les tiles du map
    for (int row = 0; row < map.rows; row++) {
      for (int col = 0; col < map.cols; col++) {
        final spriteIndex = map.getSprite(row, col);
        if (spriteIndex == 0 || tileset.isEmpty) continue;

        final dstRect = Rect.fromLTWH(
          col * map.tileSize,
          row * map.tileSize,
          map.tileSize,
          map.tileSize,
        );

        final tileImage = tileset[spriteIndex.clamp(0, tileset.length - 1)];
        canvas.drawImageRect(
          tileImage,
          Rect.fromLTWH(
            0,
            0,
            tileImage.width.toDouble(),
            tileImage.height.toDouble(),
          ),
          dstRect,
          paint,
        );
      }
    }

    // 2️⃣ Dessiner les zones en couleur semi-transparente
    if (zones != null) {
      for (var zone in zones!) {
        paint.color = zone.type == ZoneType.soil
            ? Colors.brown.withOpacity(0.4)
            : Colors.grey.withOpacity(0.4);
        canvas.drawRect(zone.rect, paint);
      }
    }

    // 3️⃣ Optionnel : contour des zones
    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (zones != null) {
      for (var zone in zones!) {
        canvas.drawRect(zone.rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TileMapPainter oldDelegate) => true;
}
