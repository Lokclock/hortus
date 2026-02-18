import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hortus_app/features/gardens/models/garden_model.dart';
import '../data/garden_repository.dart';

final gardenRepoProvider = Provider<GardenRepository>((ref) {
  return GardenRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final gardensStreamProvider = StreamProvider<List<Garden>>((ref) {
  return ref.watch(gardenRepoProvider).watchUserGardens();
});

final accessibleGardensProvider = StreamProvider<List<Garden>>((ref) {
  return ref.watch(gardenRepoProvider).watchAccessibleGardens();
});
