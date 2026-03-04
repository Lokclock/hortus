import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// 🌍 Convertit un point écran (screen) → coordonnées monde (world)
Offset screenToWorld({
  required Offset screenPoint,
  required Offset translation,
  required double scale,
  required double rotation,
  required Size viewportSize,
}) {
  // Centre de l'écran
  final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

  // Coordonnée relative au centre et translation
  final relative = screenPoint - center - translation;

  // Rotation inverse
  final cosR = math.cos(-rotation);
  final sinR = math.sin(-rotation);
  final rotated = Offset(
    relative.dx * cosR - relative.dy * sinR,
    relative.dx * sinR + relative.dy * cosR,
  );

  // Scale inverse et remise au centre
  final world = rotated / scale + center;

  return world;
}

/// 🔄 Convertit un point monde → coordonnées écran
Offset worldToScreen({
  required Offset worldPoint,
  required Offset translation,
  required double scale,
  required double rotation,
  required Size viewportSize,
}) {
  final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

  // relative au centre
  final relative = (worldPoint - center) * scale;

  // appliquer rotation
  final cosR = math.cos(rotation);
  final sinR = math.sin(rotation);
  final rotated = Offset(
    relative.dx * cosR - relative.dy * sinR,
    relative.dx * sinR + relative.dy * cosR,
  );

  // translation et retour aux coordonnées écran
  return rotated + center + translation;
}

/// 🌱 Convertit une distance monde (ex: cm ou px map) → pixels écran
double worldDistanceToScreen({
  required double distance,
  required double scale,
}) {
  return distance * scale;
}

/// 🌱 Convertit une distance écran → distance monde
double screenDistanceToWorld({
  required double distance,
  required double scale,
}) {
  return distance / scale;
}
