import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hortus_app/features/map/generate_tilemap_image.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';

/// TileType et extension pour convertir vers/depuis int
enum TileType { empty, soil, hard }

extension TileTypeExt on TileType {
  int get value {
    switch (this) {
      case TileType.empty:
        return 0;
      case TileType.soil:
        return 1;
      case TileType.hard:
        return 2;
    }
  }

  static TileType fromValue(int v) {
    switch (v) {
      case 1:
        return TileType.soil;
      case 2:
        return TileType.hard;
      case 0:
      default:
        return TileType.empty;
    }
  }
}

/// Charger les images assets une seule fois
final soilImageProvider = FutureProvider<ui.Image>((ref) async {
  final data = await rootBundle.load('assets/tiles/tilemap_soil.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
});

final hardImageProvider = FutureProvider<ui.Image>((ref) async {
  final data = await rootBundle.load('assets/tiles/tilemap_hard_v2.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
});

/// Génère l'image finale de la tilemap pour un jardin
final tilemapProvider = FutureProvider.family<ui.Image?, String>((
  ref,
  gardenId,
) async {
  // 🔹 Récupérer la tilemap Firestore
  final doc = await FirebaseFirestore.instance
      .collection('gardens')
      .doc(gardenId)
      .get();
  final data = doc.data();
  if (data == null) return null;

  final flatTiles = (data['tilemap'] as List<dynamic>).cast<int>();
  final tilesWide = data['tilesWide'] as int;
  final tilesHigh = data['tilesHigh'] as int;
  final tileSize = data['tileSize'] as double;

  final tiles = List.generate(
    tilesHigh,
    (y) => List.generate(
      tilesWide,
      (x) => TileTypeExt.fromValue(flatTiles[y * tilesWide + x]),
    ),
  );

  // 🔹 Charger les images assets
  final soilImage = await ref.watch(soilImageProvider.future);
  final hardImage = await ref.watch(hardImageProvider.future);

  // 🔹 Générer une image unique pour le canvas
  return generateTilemapImage(tiles, tileSize, soilImage, hardImage);
});
