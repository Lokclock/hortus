import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/gardens/data/garden_repository.dart';

final gardensRepositoryProvider = Provider((ref) {
  return GardenRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});
