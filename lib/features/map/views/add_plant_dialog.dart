import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';

class AddPlantDialog extends ConsumerStatefulWidget {
  final String gardenId;
  final double x;
  final double y;

  const AddPlantDialog({
    required this.gardenId,
    required this.x,
    required this.y,
  });

  @override
  ConsumerState<AddPlantDialog> createState() => _AddPlantDialogState();
}

class _AddPlantDialogState extends ConsumerState<AddPlantDialog> {
  final nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Ajouter une plante"),
      content: TextField(
        controller: nameCtrl,
        decoration: const InputDecoration(labelText: "Nom"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () async {
            final repo = ref.read(plantRepoProvider);

            await repo.addPlant(
              Plant(
                id: "",
                gardenId: widget.gardenId,
                name: nameCtrl.text,
                x: widget.x,
                y: widget.y,
                type: "default",
              ),
            );

            Navigator.pop(context);
          },
          child: const Text("Ajouter"),
        ),
      ],
    );
  }
}
