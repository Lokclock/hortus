import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';

class PlantPlantedDate extends ConsumerStatefulWidget {
  final Plant plant;
  const PlantPlantedDate({super.key, required this.plant});

  @override
  ConsumerState<PlantPlantedDate> createState() => _PlantPlantedDateState();
}

class _PlantPlantedDateState extends ConsumerState<PlantPlantedDate> {
  late DateTime _plantedAt;

  @override
  void initState() {
    super.initState();
    _plantedAt = widget.plant.plantedAt;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _plantedAt) {
      setState(() => _plantedAt = picked);

      // 🔄 Mise à jour Firestore via Riverpod
      final repo = ref.read(plantRepoProvider);
      await repo.updatePlant(widget.plant.copyWith(plantedAt: _plantedAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _plantedAt.toLocal().toString().split(' ')[0];

    return GestureDetector(
      onLongPress: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.block,
        child: Text(
          'Planté le : $formatted',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
