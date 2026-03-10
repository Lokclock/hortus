import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class AddPlantState {
  final String? id;
  final String? name; // nom commun obligatoire
  final String? scientificName;
  final String? variety;
  final String? strate; // herb, bush, shrub, tree, vine
  final String? symbol; // symbole sur la carte
  final DateTime? plantedAt; // date de plantation
  final double? diameter; // diamètre en cm
  final Map<String, DateTimeRange?>?
  harvestType; // ex: {"fruit": DateTimeRange(...), "fleur": null}

  const AddPlantState({
    this.id,
    this.name,
    this.scientificName,
    this.variety,
    this.strate,
    this.symbol,
    this.plantedAt,
    this.diameter,
    this.harvestType,
  });

  AddPlantState copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? variety,
    String? strate,
    String? symbol,
    DateTime? plantedAt,
    double? diameter,
    Map<String, DateTimeRange?>? harvestType,
  }) {
    return AddPlantState(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      variety: variety ?? this.variety,
      strate: strate ?? this.strate,
      symbol: symbol ?? this.symbol,
      plantedAt: plantedAt ?? this.plantedAt,
      diameter: diameter ?? this.diameter,
      harvestType: harvestType ?? this.harvestType,
    );
  }
}

class AddPlantNotifier extends StateNotifier<AddPlantState> {
  AddPlantNotifier() : super(const AddPlantState());

  void reset() {
    state = const AddPlantState();
  }

  void startMovePlant(Plant plant) {
    state = AddPlantState(
      id: plant.id,
      name: plant.name,
      scientificName: plant.scientificName,
      variety: plant.variety,
      strate: plant.strate,
      symbol: plant.symbol,
      plantedAt: plant.plantedAt,
      diameter: plant.diameter,
      harvestType: plant.harvestType,
    );
  }

  void update(AddPlantState newState) {
    state = newState;
  }
}

final addPlantProvider = StateNotifierProvider<AddPlantNotifier, AddPlantState>(
  (ref) => AddPlantNotifier(),
);
