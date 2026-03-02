import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';

Future<ui.Image> generateTilemapImage(
  List<List<dynamic>> tiles,
  double tileSize,
  ui.Image soilImage,
  ui.Image hardImage,
) async {
  final tilesHigh = tiles.length;
  final tilesWide = tiles[0].length;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();

  for (int y = 0; y < tilesHigh; y++) {
    for (int x = 0; x < tilesWide; x++) {
      final type = tiles[y][x];
      ui.Image? img;

      switch (type) {
        case TileType.soil:
          img = soilImage;
          break;
        case TileType.hard:
          img = hardImage;
          break;
        case TileType.empty:
        default:
          continue;
      }

      final dstRect = Rect.fromLTWH(
        x * tileSize,
        y * tileSize,
        tileSize,
        tileSize,
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dstRect,
        paint,
      );
    }
  }

  final picture = recorder.endRecording();
  return picture.toImage(
    (tilesWide * tileSize).ceil(),
    (tilesHigh * tileSize).ceil(),
  );
}
