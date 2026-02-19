import 'package:flutter/widgets.dart';

Offset getWorldPosition({
  required TransformationController controller,
  required Size viewportSize,
}) {
  final matrix = controller.value;

  /// Inverse la matrice pour passer écran → monde
  final inverse = Matrix4.inverted(matrix);

  /// Centre de l'écran = position du viseur
  final center = Offset(viewportSize.width / 2, viewportSize.height / 2);

  /// Convertir vers coordonnées monde
  final transformed = MatrixUtils.transformPoint(inverse, center);

  return transformed;
}
