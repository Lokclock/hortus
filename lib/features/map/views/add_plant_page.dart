import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/add_plant_provider.dart';
import 'package:hortus_app/features/map/providers/map_mode_provider.dart';

class AddPlantPage extends ConsumerStatefulWidget {
  final String gardenId;

  const AddPlantPage({super.key, required this.gardenId});

  @override
  ConsumerState<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends ConsumerState<AddPlantPage> {
  final PageController _pageController = PageController();

  // STEP 1
  final nameCtrl = TextEditingController();
  final scientificCtrl = TextEditingController();
  final varietyCtrl = TextEditingController();
  DateTime plantedAt = DateTime.now();

  // STEP 2
  final harvestTypes = ['fruit', 'fleur', 'feuille', 'racine', 'bois'];
  Map<String, DateTimeRange?> selectedHarvests = {};

  // STEP 3
  final strates = ['herb', 'bush', 'shrub', 'tree', 'vine'];
  String? selectedStrate;

  // STEP 4
  final icons = ['🌱', '🌿', '🌳', '🌷', '🍎'];
  String? selectedIcon;
  final diameterCtrl = TextEditingController();

  int currentStep = 0;

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (currentStep < 3) {
      setState(() => currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Passer au PositioningOverlay
      ref.read(addPlantProvider.notifier).state = AddPlantState(
        name: nameCtrl.text,
        scientificName: scientificCtrl.text,
        variety: varietyCtrl.text,
        plantedAt: plantedAt,
        harvestType: selectedHarvests,
        strate: selectedStrate!,
        icon: selectedIcon!,
        diameter: double.parse(diameterCtrl.text),
      );

      // Activer le mode positionnement
      ref.read(mapModeProvider.notifier).state = MapMode.edit;

      // Fermer la page AddPlant
      Navigator.of(context).pop();
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (nameCtrl.text.isEmpty) {
          _showError("Le nom commun est obligatoire");
          return false;
        }
        return true;
      case 2:
        if (selectedStrate == null) {
          _showError("Veuillez sélectionner une strate");
          return false;
        }
        return true;
      case 3:
        if (selectedIcon == null || diameterCtrl.text.isEmpty) {
          _showError("Veuillez choisir un symbole et entrer le diamètre");
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une plante")),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4()],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _nextStep,
          child: Text(currentStep < 3 ? "Suivant" : "Terminer"),
        ),
      ),
    );
  }

  // -------------------- STEP 1 --------------------
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: "Nom commun *"),
          ),
          TextField(
            controller: scientificCtrl,
            decoration: const InputDecoration(labelText: "Nom scientifique"),
          ),
          TextField(
            controller: varietyCtrl,
            decoration: const InputDecoration(labelText: "Variété"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Planté le : "),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: plantedAt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => plantedAt = date);
                },
                child: Text(
                  "${plantedAt.day}/${plantedAt.month}/${plantedAt.year}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- STEP 2 --------------------
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          /// Liste de récoltes
          Column(
            children: harvestTypes.map((type) {
              final selected = selectedHarvests.containsKey(type);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      selectedHarvests.remove(type);
                    } else {
                      selectedHarvests[type] = null;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: selected ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(type)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(width: 16),

          /// Sélection de période
          Expanded(
            child: Column(
              children: selectedHarvests.keys.map((type) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Période $type :"),
                    TextButton(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (range != null) {
                          setState(() => selectedHarvests[type] = range);
                        }
                      },
                      child: Text(
                        selectedHarvests[type] != null
                            ? "${selectedHarvests[type]!.start.day}/${selectedHarvests[type]!.start.month} - ${selectedHarvests[type]!.end.day}/${selectedHarvests[type]!.end.month}"
                            : "Non précisée",
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- STEP 3 --------------------
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: strates.map((s) {
          final selected = selectedStrate == s;
          return ListTile(
            title: Text(s),
            tileColor: selected ? Colors.green.shade200 : null,
            onTap: () => setState(() => selectedStrate = s),
          );
        }).toList(),
      ),
    );
  }

  // -------------------- STEP 4 --------------------
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            children: icons.map((i) {
              final selected = selectedIcon == i;
              return GestureDetector(
                onTap: () => setState(() => selectedIcon = i),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selected ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(i, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: diameterCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Diamètre (cm) *"),
          ),
        ],
      ),
    );
  }
}
