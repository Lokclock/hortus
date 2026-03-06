import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/map/providers/edit_plant_provider.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class EditStrateSheet extends ConsumerStatefulWidget {
  final Plant plant;
  const EditStrateSheet({super.key, required this.plant});

  @override
  ConsumerState<EditStrateSheet> createState() => _EditStrateSheetState();
}

class _EditStrateSheetState extends ConsumerState<EditStrateSheet> {
  static const assets = {
    'Herbacée': 'assets/images/strates/herb.png',
    'Buisson': 'assets/images/strates/bush.png',
    'Liane': 'assets/images/strates/vine.png',
    'Arbuste': 'assets/images/strates/tree.png',
    'Canopée': 'assets/images/strates/canopee.png',
  };

  String? selectedStrate;

  @override
  void initState() {
    super.initState();
    selectedStrate = widget.plant.strate; // récupère la valeur actuelle
  }

  void updateProvider() {
    ref
        .read(editPlantProvider(widget.plant).notifier)
        .update(strate: selectedStrate);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppDecorations.sheet,
        child: SizedBox(
          height: 610,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: ListView.separated(
                    itemCount: assets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = assets.entries.elementAt(index);
                      final selected = selectedStrate == entry.key;

                      return _AnimatedTile(
                        asset: entry.value,
                        label: entry.key,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            selectedStrate = entry.key;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Bouton Enregistrer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // met à jour le provider
                    ref
                        .read(editPlantProvider(widget.plant).notifier)
                        .update(strate: selectedStrate);

                    // ferme la sheet
                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(8),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(height: 68, child: Image.asset(asset)),

              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: selected ? Colors.green : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
