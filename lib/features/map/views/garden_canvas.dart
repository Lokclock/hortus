import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/map/views/add_plant_dialog.dart';

class GardenCanvas extends ConsumerWidget {
  final String gardenId;
  final List<Plant> plants;
  final bool canEdit;

  const GardenCanvas({
    required this.gardenId,
    required this.plants,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InteractiveViewer(
      maxScale: 4,
      minScale: 0.5,
      child: GestureDetector(
        onTapUp: canEdit
            ? (details) {
                final pos = details.localPosition;

                _showAddPlantDialog(context, ref, pos);
              }
            : null,
        child: Container(
          width: 2000,
          height: 2000,
          color: Colors.green.shade50,
          child: Stack(
            children: plants.map((p) {
              return Positioned(
                left: p.x,
                top: p.y,
                child: const Icon(Icons.local_florist, color: Colors.green),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddPlantDialog(BuildContext context, WidgetRef ref, Offset pos) {
    showDialog(
      context: context,
      builder: (_) => AddPlantDialog(gardenId: gardenId, x: pos.dx, y: pos.dy),
    );
  }
}
