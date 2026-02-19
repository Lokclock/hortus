import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';

class AddPlantSheet extends ConsumerStatefulWidget {
  final String gardenId;

  const AddPlantSheet({required this.gardenId, super.key});

  @override
  ConsumerState<AddPlantSheet> createState() => _AddPlantSheetState();
}

class _AddPlantSheetState extends ConsumerState<AddPlantSheet> {
  final nameCtrl = TextEditingController();
  final scientificCtrl = TextEditingController();
  final varietyCtrl = TextEditingController();

  String selectedType = 'fruit'; // valeur initiale
  String selectedStrate = 'herb'; // valeur initiale
  String selectedIcon = '🌱'; // valeur initiale

  DateTime? plantedAt;
  DateTime? harvestAt;

  final types = ['fruit', 'flower', 'root', 'leaf', 'wood'];
  final strates = ['herb', 'bush', 'shrub', 'tree', 'vine'];
  final icons = ['🌱', '🌿', '🌳', '🌷', '🍎'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ajouter une plante",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nom commun"),
            ),
            TextField(
              controller: scientificCtrl,
              decoration: const InputDecoration(labelText: "Nom scientifique"),
            ),
            TextField(
              controller: varietyCtrl,
              decoration: const InputDecoration(labelText: "Variété"),
            ),
            const SizedBox(height: 12),

            /// Dropdown type de récolte
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(labelText: "Type de récolte"),
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => selectedType = val!),
            ),

            const SizedBox(height: 12),

            /// Dropdown strate
            DropdownButtonFormField<String>(
              value: selectedStrate,
              decoration: const InputDecoration(labelText: "Strate végétale"),
              items: strates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => selectedStrate = val!),
            ),

            const SizedBox(height: 12),

            /// Dropdown icône
            DropdownButtonFormField<String>(
              value: selectedIcon,
              decoration: const InputDecoration(labelText: "Icône"),
              items: icons
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: (val) => setState(() => selectedIcon = val!),
            ),

            const SizedBox(height: 12),

            /// Bouton ajouter
            ElevatedButton(
              onPressed: () {
                // 1️⃣ Pré-remplir le provider
                ref.read(addPlantProvider.notifier).state = AddPlantState(
                  name: nameCtrl.text,
                  type: selectedType,
                  strate: selectedStrate,
                  icon: selectedIcon,
                  plantedAt: plantedAt,
                  harvestAt: harvestAt,
                );

                // 2️⃣ Activer le mode positionnement
                ref.read(mapModeProvider.notifier).state = MapMode.edit;

                // 3️⃣ Fermer la bottom sheet
                Navigator.pop(context);
              },
              child: const Text("Ajouter"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
