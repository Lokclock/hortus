import 'package:flutter/material.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';

class PlantPlantedDate extends StatelessWidget {
  final DateTime date;

  const PlantPlantedDate({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final formatted = date.toLocal().toString().split(' ')[0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.block,
      child: Text(
        'Planté le : $formatted',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
