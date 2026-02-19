import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MapMode { view, addPlant, movePlant, edit }

final mapModeProvider = StateProvider<MapMode>((ref) {
  return MapMode.view;
});
