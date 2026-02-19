import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddPlantState {
  final String? id;
  final String? name;
  final String? scientificName;
  final String? variety;
  final String? type; // type de récolte
  final String? strate; // strate végétale
  final String? icon; // icône
  final DateTime? plantedAt;
  final DateTime? harvestAt;

  const AddPlantState({
    this.id,
    this.name,
    this.scientificName,
    this.variety,
    this.type,
    this.strate,
    this.icon,
    this.plantedAt,
    this.harvestAt,
  });

  AddPlantState copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? variety,
    String? type,
    String? strate,
    String? icon,
    DateTime? plantedAt,
    DateTime? harvestAt,
  }) {
    return AddPlantState(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      variety: variety ?? this.variety,
      type: type ?? this.type,
      strate: strate ?? this.strate,
      icon: icon ?? this.icon,
      plantedAt: plantedAt ?? this.plantedAt,
      harvestAt: harvestAt ?? this.harvestAt,
    );
  }
}

// Provider pour gérer l'état temporaire avant validation sur la carte
final addPlantProvider = StateProvider<AddPlantState>(
  (ref) => const AddPlantState(),
);
