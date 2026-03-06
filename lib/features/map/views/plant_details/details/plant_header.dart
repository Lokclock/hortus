import 'package:flutter/material.dart';
import 'package:hortus_app/core/theme/app_decorations.dart';
import 'package:hortus_app/features/map/views/plant_details/edit/edit_plant_sheet.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class PlantHeader extends StatelessWidget {
  final Plant plant;

  const PlantHeader({super.key, required this.plant});

  void _openEditInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditPlantSheet(plant: plant),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: plant.imageUrl != null
              ? Image.network(
                  plant.imageUrl!,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 120,
                  height: 120,
                  color: Colors.green.shade100,
                  child: const Icon(Icons.local_florist, size: 64),
                ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: InkWell(
            onTap: () => _openEditInfo(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: AppDecorations.block,
              height: 120,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (plant.scientificName != null)
                      Text(
                        plant.scientificName!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                        ),
                      ),

                    if (plant.variety != null)
                      Text(
                        "'${plant.variety!}'",
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
