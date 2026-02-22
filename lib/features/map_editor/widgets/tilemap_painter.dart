import 'package:flutter/material.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';

class GardenPainter extends CustomPainter {
  final List<List<TileType>> tiles;
  final double tileSize;
  final Offset? selectionStart;
  final Offset? selectionEnd;

  GardenPainter({
    required this.tiles,
    required this.tileSize,
    this.selectionStart,
    this.selectionEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fond bleu sur tout l'écran
    final sizePlus = Size(size.width + 800, size.height + 800);
    final rectBackgroundPaint = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;
    canvas.drawRect(Offset(-400, -400) & sizePlus, rectBackgroundPaint);

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
        if (t != TileType.empty) {
          final color = t == TileType.soil
              ? const Color.fromARGB(255, 57, 142, 52)
              : t == TileType.hard
              ? Color.fromARGB(255, 4, 99, 143)
              : const Color.fromARGB(0, 4, 99, 143);
          canvas.drawRect(
            Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize),
            Paint()..color = color.withOpacity(0.7),
          );
        }
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
