import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/data/plant_repository.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

final plantRepoProvider = Provider(
  (ref) => PlantRepository(FirebaseFirestore.instance),
);

final plantsStreamProvider = StreamProvider.family<List<Plant>, String>((
  ref,
  gardenId,
) {
  return ref.watch(plantRepoProvider).watchPlants(gardenId);
});
