import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapTransformProvider = Provider<TransformationController>((ref) {
  return TransformationController();
});
