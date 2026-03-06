import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/map/providers/edit_plant_provider.dart';

class EditHarvestSheet extends ConsumerStatefulWidget {
  final Plant plant;

  const EditHarvestSheet({super.key, required this.plant});

  @override
  ConsumerState<EditHarvestSheet> createState() => _EditHarvestSheetState();
}

class _EditHarvestSheetState extends ConsumerState<EditHarvestSheet> {
  final Map<String, String> harvestImages = {
    'fruit': 'assets/images/recoltes/fruit.png',
    'fleur': 'assets/images/recoltes/fleur.png',
    'feuille': 'assets/images/recoltes/feuille.png',
    'racine': 'assets/images/recoltes/racine.png',
    'bois': 'assets/images/recoltes/bois.png',
  };

  late Map<String, DateTimeRange?> localHarvests;

  @override
  void initState() {
    super.initState();
    final state = ref.read(editPlantProvider(widget.plant));
    localHarvests = Map<String, DateTimeRange?>.from(state.harvestType ?? {});
  }

  void updateProvider() {
    final notifier = ref.read(editPlantProvider(widget.plant).notifier);
    notifier.updateHarvest(localHarvests);
  }

  Future<void> pickDateRange(String type) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          localHarvests[type] ??
          DateTimeRange(start: now, end: now.add(const Duration(days: 7))),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Récoltes",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: harvestImages.entries.map((entry) {
                  final type = entry.key;
                  final image = entry.value;
                  final isSelected = localHarvests.containsKey(type);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                localHarvests.remove(type);
                              } else {
                                localHarvests[type] = null;
                              }
                              updateProvider();
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green[200]
                                  : Colors.grey[200],
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
                        if (isSelected)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickDateRange(type),
                              child: Container(
                                height: 60,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  localHarvests[type] != null
                                      ? 'Période : ${localHarvests[type]!.start.day}/${localHarvests[type]!.start.month} - ${localHarvests[type]!.end.day}/${localHarvests[type]!.end.month}'
                                      : 'Période : .../... - .../...',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final notifier = ref.read(
                    editPlantProvider(widget.plant).notifier,
                  );
                  await notifier.save(); // sauvegarde dans Firestore
                  if (mounted) Navigator.of(context).pop(); // ferme la sheet
                },
                child: const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
