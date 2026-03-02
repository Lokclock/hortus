import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class OverlayImagePainter extends CustomPainter {
  final ui.Image image;
  final double opacity;
  final Offset offset;
  final double scale;

  OverlayImagePainter({
    required this.image,
    required this.opacity,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(opacity);

    final dstWidth = image.width * scale;
    final dstHeight = image.height * scale;

    final dstRect = Rect.fromLTWH(offset.dx, offset.dy, dstWidth, dstHeight);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dstRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant OverlayImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.opacity != opacity ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale;
  }
}
