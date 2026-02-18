import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

class PlantRepository {
  final FirebaseFirestore _firestore;

  PlantRepository(this._firestore);

  CollectionReference plantsRef(String gardenId) =>
      _firestore.collection('gardens').doc(gardenId).collection('plants');

  /// Stream des plantes d'un jardin
  Stream<List<Plant>> watchPlants(String gardenId) {
    return plantsRef(gardenId).snapshots().map(
      (snapshot) => snapshot.docs
          .map((d) => Plant.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  /// Ajouter plante
  Future<void> addPlant(Plant plant) async {
    await plantsRef(plant.gardenId).add(plant.toMap());
  }

  /// Supprimer
  Future<void> deletePlant(String gardenId, String plantId) async {
    await plantsRef(gardenId).doc(plantId).delete();
  }
}
