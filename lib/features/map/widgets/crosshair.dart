import 'package:flutter/material.dart';

class Crosshair extends StatelessWidget {
  const Crosshair({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final paint = Paint()
      ..color = const Color.fromARGB(0, 255, 255, 255)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    const gap = 14.0; // espace autour du centre
    const length = 30; // longueur des traits

    /// Pixel central
    canvas.drawCircle(center, 1, Paint()..color = Colors.white);

    /// Trait haut
    canvas.drawLine(
      Offset(center.dx, center.dy - gap),
      Offset(center.dx, center.dy - gap - length),
      linePaint,
    );

    /// Trait bas
    canvas.drawLine(
      Offset(center.dx, center.dy + gap),
      Offset(center.dx, center.dy + gap + length),
      linePaint,
    );

    /// Trait gauche
    canvas.drawLine(
      Offset(center.dx - gap, center.dy),
      Offset(center.dx - gap - length, center.dy),
      linePaint,
    );

    /// Trait droite
    canvas.drawLine(
      Offset(center.dx + gap, center.dy),
      Offset(center.dx + gap + length, center.dy),
      linePaint,
    );

    /// Cercle vide autour du centre
    canvas.drawCircle(center, gap, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
