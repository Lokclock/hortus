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
  int step = 0;
  final controller = PageController();

  void next() {
    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    setState(() => step++);
  }

  void back() {
    controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    setState(() => step--);
  }

  bool canProceed(AddPlantState state) {
    switch (step) {
      case 0:
        return state.name != null && state.name!.trim().isNotEmpty;

      case 2:
        return state.strate != null && state.strate!.isNotEmpty;

      case 3:
        return state.symbol != null &&
            state.symbol!.isNotEmpty &&
            state.diameter != null;

      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPlantProvider);
    final valid = canProceed(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une plante"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(addPlantProvider.notifier).state = const AddPlantState();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: (step + 1) / 4),

          Expanded(
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepInfo(),
                _StepHarvest(),
                _StepStrate(),
                _StepSymbol(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (step > 0)
                  ElevatedButton(onPressed: back, child: const Text("Retour")),
                const Spacer(),
                ElevatedButton(
                  onPressed: valid
                      ? () {
                          if (step == 3) {
                            ref.read(mapModeProvider.notifier).state =
                                MapMode.addPlant;
                            Navigator.pop(context);
                          } else {
                            next();
                          }
                        }
                      : null,
                  child: Text(step == 3 ? "Positionner" : "Suivant"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo extends ConsumerWidget {
  const _StepInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPlantProvider);
    final plantedDate = state.plantedAt ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text("Informations", style: TextStyle(fontSize: 20)),

          const SizedBox(height: 20),

          TextField(
            decoration: const InputDecoration(
              labelText: "Nom commun *",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => ref.read(addPlantProvider.notifier).state = state
                .copyWith(name: v),
          ),

          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(
              labelText: "Nom scientifique",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => ref.read(addPlantProvider.notifier).state = state
                .copyWith(scientificName: v),
          ),

          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(
              labelText: "Variété",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => ref.read(addPlantProvider.notifier).state = state
                .copyWith(variety: v),
          ),

          const SizedBox(height: 24),

          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: plantedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(addPlantProvider.notifier).state = state.copyWith(
                  plantedAt: picked,
                );
              }
            },
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                "${plantedDate.day}/${plantedDate.month}/${plantedDate.year}",
              ),
              titleTextStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHarvest extends ConsumerStatefulWidget {
  const _StepHarvest({super.key});

  @override
  ConsumerState<_StepHarvest> createState() => _StepHarvestState();
}

class _StepHarvestState extends ConsumerState<_StepHarvest> {
  // Liste des types de récoltes avec leur image
  final Map<String, String> harvestImages = {
    'fruit': 'assets/images/recoltes/fruit.png',
    'fleur': 'assets/images/recoltes/fleur.png',
    'feuille': 'assets/images/recoltes/feuille.png',
    'racine': 'assets/images/recoltes/racine.png',
    'bois': 'assets/images/recoltes/bois.png',
  };

  // état local pour ce step
  late Map<String, DateTimeRange?> localHarvests;

  @override
  void initState() {
    super.initState();
    final providerValue = ref.read(addPlantProvider);
    localHarvests = Map<String, DateTimeRange?>.from(
      providerValue.harvestType ?? {},
    ); // récup si existant
  }

  // update le provider à chaque changement
  void updateProvider() {
    ref.read(addPlantProvider.notifier).state = ref
        .read(addPlantProvider)
        .copyWith(harvestType: localHarvests);
  }

  Future<void> pickDateRange(String type) async {
    final now = DateTime.now();
    final initialRange =
        localHarvests[type] ??
        DateTimeRange(start: now, end: now.add(const Duration(days: 7)));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        localHarvests[type] = picked;
        updateProvider();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: harvestImages.length,
      itemBuilder: (context, index) {
        final type = harvestImages.keys.elementAt(index);
        final image = harvestImages[type]!;
        final isSelected = localHarvests.containsKey(type);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image + tile
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      localHarvests.remove(type);
                    } else {
                      localHarvests[type] = null; // active mais pas de période
                    }
                    updateProvider();
                  });
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[200] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(image),
                ),
              ),

              const SizedBox(width: 16),

              // zone de période si sélectionné
              Expanded(
                child: isSelected
                    ? GestureDetector(
                        onTap: () => pickDateRange(type),
                        child: Container(
                          height: 70,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            localHarvests[type] != null
                                ? 'Période : ${localHarvests[type]!.start.day}/${localHarvests[type]!.start.month} - ${localHarvests[type]!.end.day}/${localHarvests[type]!.end.month}'
                                : 'Période : .../... - .../...',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepStrate extends ConsumerWidget {
  const _StepStrate();

  static const assets = {
    'herb': 'assets/images/strates/herb.png',
    'bush': 'assets/images/strates/bush.png',
    'shrub': 'assets/images/strates/canopee.png',
    'tree': 'assets/images/strates/tree.png',
    'vine': 'assets/images/strates/vine.png',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPlantProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: assets.entries.map((e) {
          final selected = state.strate == e.key;

          return _AnimatedTile(
            asset: e.value,
            label: e.key,
            selected: selected,
            onTap: () {
              ref.read(addPlantProvider.notifier).state = state.copyWith(
                strate: e.key,
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _StepSymbol extends ConsumerStatefulWidget {
  const _StepSymbol({super.key});

  @override
  ConsumerState<_StepSymbol> createState() => _StepSymbolState();
}

class _StepSymbolState extends ConsumerState<_StepSymbol> {
  // Liste des symboles disponibles
  final List<String> symbols = [
    'assets/images/symboles/achillee.png',
    'assets/images/symboles/baies_aux_cinq_saveurs.png',
    'assets/images/symboles/camerisier.png',
    'assets/images/symboles/cassisier.png',
    'assets/images/symboles/chou_daubenton.png',
    'assets/images/symboles/consoude.png',
    'assets/images/symboles/fraisier.png',
    'assets/images/symboles/kiwai.png',
    'assets/images/symboles/pommier.png',
    'assets/images/symboles/robinier_faux-acacia.png',
    'assets/images/symboles/thym.png',
    'assets/images/symboles/yuzu.png',
  ];

  String? selectedSymbol;
  double? diameter;

  @override
  void initState() {
    super.initState();
    final provider = ref.read(addPlantProvider);
    selectedSymbol = provider.symbol;
    diameter = provider.diameter;
  }

  void updateProvider() {
    ref.read(addPlantProvider.notifier).state = ref
        .read(addPlantProvider)
        .copyWith(symbol: selectedSymbol, diameter: diameter);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Choisissez un symbole pour votre plante',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Grille des symboles
            Expanded(
              child: GridView.builder(
                itemCount: symbols.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final symbol = symbols[index];
                  final isSelected = selectedSymbol == symbol;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSymbol = symbol;
                        updateProvider();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.grey,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? Colors.green[100]
                            : Colors.grey[200],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(symbol),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Champ diamètre
            TextFormField(
              initialValue: diameter?.toString(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Diamètre (cm)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                setState(() {
                  diameter = parsed;
                  updateProvider();
                });
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AnimatedTile extends StatelessWidget {
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AnimatedTile({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Colors.green.withOpacity(.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Expanded(child: Image.asset(asset)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.green : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
