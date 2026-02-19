import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class AddPlantPage extends ConsumerStatefulWidget {
  final String gardenId;
  final Plant? plant; // si non null -> update

  const AddPlantPage({required this.gardenId, this.plant, super.key});

  @override
  ConsumerState<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends ConsumerState<AddPlantPage> {
  late TextEditingController nameCtrl;
  late TextEditingController scientificCtrl;
  late TextEditingController varietyCtrl;

  String selectedType = 'fruit';
  String selectedStrate = 'herb';
  String selectedIcon = '🌱';

  DateTime? plantedAt;
  DateTime? harvestAt;

  final types = ['fruit', 'flower', 'root', 'leaf', 'wood'];
  final typeImages = {
    'fruit': 'assets/images/harvest_fruit.png',
    'flower': 'assets/images/harvest_flower.png',
    'root': 'assets/images/harvest_root.png',
    'leaf': 'assets/images/harvest_leaf.png',
    'wood': 'assets/images/harvest_wood.png',
  };

  final strates = ['herb', 'bush', 'shrub', 'tree', 'vine'];
  final strateImages = {
    'herb': 'assets/images/strate_herb.png',
    'bush': 'assets/images/strate_bush.png',
    'shrub': 'assets/images/strate_shrub.png',
    'tree': 'assets/images/strate_tree.png',
    'vine': 'assets/images/strate_vine.png',
  };

  final icons = ['🌱', '🌿', '🌳', '🌷', '🍎'];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.plant?.name ?? '');
    scientificCtrl = TextEditingController(
      text: widget.plant?.scientificName ?? '',
    );
    varietyCtrl = TextEditingController(text: widget.plant?.variety ?? '');
    selectedType = widget.plant?.type ?? 'fruit';
    selectedStrate = widget.plant?.strate ?? 'herb';
    plantedAt = widget.plant?.plantedAt;
    harvestAt = widget.plant?.harvestAt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plant != null ? 'Modifier plante' : 'Ajouter plante',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nom commun"),
              ),
              TextField(
                controller: scientificCtrl,
                decoration: const InputDecoration(
                  labelText: "Nom scientifique",
                ),
              ),
              TextField(
                controller: varietyCtrl,
                decoration: const InputDecoration(labelText: "Variété"),
              ),
              const SizedBox(height: 16),
              // Type récolte avec image
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Type de récolte"),
                items: types.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Image.asset(typeImages[t]!, width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(t),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedType = val!),
              ),
              const SizedBox(height: 12),
              // Strate avec image
              DropdownButtonFormField<String>(
                value: selectedStrate,
                decoration: const InputDecoration(labelText: "Strate végétale"),
                items: strates.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Image.asset(strateImages[s]!, width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(s),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedStrate = val!),
              ),
              const SizedBox(height: 12),
              // Icône
              DropdownButtonFormField<String>(
                value: selectedIcon,
                decoration: const InputDecoration(labelText: "Icône"),
                items: icons
                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                    .toList(),
                onChanged: (val) => setState(() => selectedIcon = val!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final addPlantNotifier = ref.read(addPlantProvider.notifier);
                  addPlantNotifier.state = AddPlantState(
                    id: widget.plant?.id,
                    name: nameCtrl.text,
                    scientificName: scientificCtrl.text,
                    variety: varietyCtrl.text,
                    type: selectedType,
                    strate: selectedStrate,
                    icon: selectedIcon,
                    plantedAt: plantedAt,
                    harvestAt: harvestAt,
                  );
                  ref.read(mapModeProvider.notifier).state = MapMode.edit;
                  Navigator.pop(context);
                },
                child: Text(widget.plant != null ? "Modifier" : "Ajouter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
