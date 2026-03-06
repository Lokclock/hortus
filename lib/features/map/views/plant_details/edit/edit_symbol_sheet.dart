import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/map/providers/edit_plant_provider.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class EditSymbolSheet extends ConsumerStatefulWidget {
  final Plant plant;

  const EditSymbolSheet({super.key, required this.plant});

  @override
  ConsumerState<EditSymbolSheet> createState() => _EditSymbolSheetState();
}

class _EditSymbolSheetState extends ConsumerState<EditSymbolSheet> {
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

  late String selectedSymbol;
  late TextEditingController diameterController;

  @override
  void initState() {
    super.initState();

    selectedSymbol = widget.plant.symbol;

    diameterController = TextEditingController(
      text: widget.plant.diameter.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    diameterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(editPlantProvider(widget.plant).notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Modifier symbole et diamètre",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 300,
              child: GridView.builder(
                itemCount: symbols.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final symbol = symbols[index];
                  final isSelected = symbol == selectedSymbol;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSymbol = symbol;
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

            TextField(
              controller: diameterController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: "Diamètre (cm)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                final diameter = double.tryParse(diameterController.text);

                notifier.update(symbol: selectedSymbol, diameter: diameter);

                await notifier.save();

                Navigator.pop(context);
              },
              child: const Text("Enregistrer"),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
