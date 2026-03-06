import 'package:flutter/material.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/map/views/plant_details/edit/edit_symbol_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class PlantInfoBar extends StatelessWidget {
  final Plant plant;

  const PlantInfoBar({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDecorations.sheet,
                child: EditSymbolSheet(plant: plant),
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: AppDecorations.block,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (plant.symbol != null)
              Image.asset(plant.symbol!, width: 60, height: 60),

            Text(
              '${plant.diameter.toStringAsFixed(0)} cm',
              style: const TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),

            IconButton(icon: const Icon(Icons.place), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
