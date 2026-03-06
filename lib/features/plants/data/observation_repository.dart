import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hortus_app/features/plants/models/observation_model.dart';

class ObservationRepository {
  final FirebaseFirestore _firestore;

  ObservationRepository(this._firestore);

  CollectionReference messagesRef(String plantId) =>
      _firestore.collection('plants').doc(plantId).collection('observations');

  Stream<List<ObservationMessage>> watchMessages(String plantId) {
    return messagesRef(plantId)
        .orderBy('timestamp', descending: true) // de bas en haut
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (d) => ObservationMessage.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList(),
        );
  }

  Future<void> addMessage(String plantId, ObservationMessage message) async {
    await messagesRef(plantId).add(message.toMap());
  }

  Future<void> updateMessage(String plantId, ObservationMessage message) async {
    await messagesRef(plantId).doc(message.id).update(message.toMap());
  }
}
