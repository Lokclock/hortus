import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/data/plant_repository.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

/// 🌿 Clé immutable pour identifier une plante unique
class PlantKey {
  final String gardenId;
  final String plantId;

  const PlantKey({required this.gardenId, required this.plantId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantKey &&
          runtimeType == other.runtimeType &&
          gardenId == other.gardenId &&
          plantId == other.plantId;

  @override
  int get hashCode => gardenId.hashCode ^ plantId.hashCode;
}

/// 🌿 Repository Provider
final plantRepoProvider = Provider<PlantRepository>((ref) {
  return PlantRepository(FirebaseFirestore.instance);
});

/// 🌱 StreamProvider pour toutes les plantes d'un jardin
final plantsStreamProvider = StreamProvider.family<List<Plant>, String>((
  ref,
  gardenId,
) {
  final repo = ref.watch(plantRepoProvider);
  return repo.watchPlants(gardenId);
});

/// 🌿 StreamProvider pour une plante spécifique
final plantByIdProvider = StreamProvider.family<Plant, PlantKey>((ref, key) {
  final repo = ref.watch(plantRepoProvider);
  return repo.watchPlant(key.gardenId, key.plantId);
});
