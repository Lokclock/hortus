import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';

class TilemapArgs {
  final List<List<TileType>> tiles;
  final int tilesWide;
  final int tilesHigh;
  final double tileSize;
  final Map<int, Rect> soilRects;
  final Map<int, Rect> hardRects;
  final ui.Image soilImage;
  final ui.Image hardImage;

  TilemapArgs({
    required this.tiles,
    required this.tilesWide,
    required this.tilesHigh,
    required this.tileSize,
    required this.soilRects,
    required this.hardRects,
    required this.soilImage,
    required this.hardImage,
  });
}
