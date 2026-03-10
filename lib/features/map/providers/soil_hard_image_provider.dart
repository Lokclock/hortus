import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soilImageProvider = FutureProvider<ui.Image>((ref) async {
  final data = await rootBundle.load('assets/tiles/tilemap_soil_v2.png');
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
