import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/data/observation_repository.dart';
import 'package:hortus_app/features/plants/models/observation_model.dart';

final observationRepoProvider = Provider((ref) {
  return ObservationRepository(FirebaseFirestore.instance);
});

final messagesProvider =
    StreamProvider.family<List<ObservationMessage>, String>((ref, plantId) {
      final repo = ref.watch(observationRepoProvider);
      return repo.watchMessages(plantId);
    });
