import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// Provider pour gérer l'état temporaire avant validation sur la carte
final addPlantProvider = StateProvider<AddPlantState>(
  (ref) => const AddPlantState(),
);
