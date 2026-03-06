import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/edit_plant_provider.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class EditPlantSheet extends ConsumerStatefulWidget {
  final Plant? plant;

  const EditPlantSheet({super.key, this.plant});

  @override
  ConsumerState<EditPlantSheet> createState() => _EditPlantSheetState();
}

class _EditPlantSheetState extends ConsumerState<EditPlantSheet> {
  late TextEditingController nameController;
  late TextEditingController scientificController;
  late TextEditingController varietyController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(editPlantProvider(widget.plant));

    nameController = TextEditingController(text: state.name ?? '');
    scientificController = TextEditingController(
      text: state.scientificName ?? '',
    );
    varietyController = TextEditingController(text: state.variety ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(editPlantProvider(widget.plant).notifier);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              "Modifier la plante",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nom commun"),
              onChanged: (v) => notifier.update(name: v),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: scientificController,
              decoration: const InputDecoration(labelText: "Nom scientifique"),
              onChanged: (v) => notifier.update(scientificName: v),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: varietyController,
              decoration: const InputDecoration(labelText: "Variété"),
              onChanged: (v) => notifier.update(variety: v),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                await notifier.save();
                Navigator.pop(context); // ferme après sauvegarde
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
