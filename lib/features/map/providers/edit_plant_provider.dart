import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';
import 'package:hortus_app/features/plants/data/plant_repository.dart';
import 'package:hortus_app/features/plants/providers/plant_providers.dart';

class EditPlantState {
  final Plant? originalPlant;
  final String? name;
  final String? scientificName;
  final String? variety;
  final String? strate;
  final String? symbol;
  final DateTime? plantedAt;
  final double? diameter;
  final double? x;
  final double? y;
  final Map<String, DateTimeRange?>? harvestType;

  EditPlantState({
    required this.originalPlant,
    this.name,
    this.scientificName,
    this.variety,
    this.strate,
    this.symbol,
    this.plantedAt,
    this.diameter,
    this.x,
    this.y,
    this.harvestType,
  });

  EditPlantState copyWith({
    String? name,
    String? scientificName,
    String? variety,
    String? strate,
    String? symbol,
    DateTime? plantedAt,
    double? diameter,
    double? x,
    double? y,
    Map<String, DateTimeRange?>? harvestType,
  }) {
    return EditPlantState(
      originalPlant: originalPlant,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      variety: variety ?? this.variety,
      strate: strate ?? this.strate,
      symbol: symbol ?? this.symbol,
      plantedAt: plantedAt ?? this.plantedAt,
      diameter: diameter ?? this.diameter,
      x: x ?? this.x,
      y: y ?? this.y,
      harvestType: harvestType ?? Map.from(this.harvestType ?? {}),
    );
  }
}

class EditPlantNotifier extends StateNotifier<EditPlantState> {
  final PlantRepository repository;
  final String gardenId;

  EditPlantNotifier(this.repository, this.gardenId, EditPlantState initialState)
    : super(initialState);

  void updateHarvest(Map<String, DateTimeRange?> harvests) {
    state = state.copyWith(harvestType: harvests);
  }

  void update({
    String? name,
    String? scientificName,
    String? variety,
    String? strate,
    String? symbol,
    DateTime? plantedAt,
    double? diameter,
    double? x,
    double? y,
    Map<String, DateTimeRange?>? harvestType, // AJOUT
  }) {
    state = state.copyWith(
      name: name,
      scientificName: scientificName,
      variety: variety,
      strate: strate,
      symbol: symbol,
      plantedAt: plantedAt,
      diameter: diameter,
      harvestType: harvestType, // AJOUT
    );
  }

  Future<void> save() async {
    if (state.originalPlant == null) return;

    final updatedPlant = state.originalPlant!.copyWith(
      name: state.name,
      scientificName: state.scientificName,
      variety: state.variety,
      strate: state.strate,
      symbol: state.symbol,
      plantedAt: state.plantedAt,
      diameter: state.diameter,
      harvestType: state.harvestType,
    );

    await repository.updatePlant(updatedPlant);
  }
}

final editPlantProvider =
    StateNotifierProvider.family<EditPlantNotifier, EditPlantState, Plant?>((
      ref,
      plant,
    ) {
      final repo = ref.watch(plantRepoProvider);

      return EditPlantNotifier(
        repo,
        plant?.gardenId ?? '',
        EditPlantState(
          originalPlant: plant, // ⚡ garde tout le Plant original
          name: plant?.name,
          scientificName: plant?.scientificName,
          variety: plant?.variety,
          strate: plant?.strate,
          symbol: plant?.symbol,
          plantedAt: plant?.plantedAt,
          diameter: plant?.diameter,
          harvestType: plant?.harvestType,
        ),
      );
    });
