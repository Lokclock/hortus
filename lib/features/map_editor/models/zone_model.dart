import 'package:flutter/material.dart';

enum ZoneType { soil, hard }

class Zone {
  final Rect rect;
  final ZoneType type;

  Zone({required this.rect, required this.type});
}
