import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hortus_app/features/plants/models/observation_model.dart';

class ObservationRepository {
  final FirebaseFirestore _firestore;

  ObservationRepository(this._firestore);

  CollectionReference messagesRef(String gardenId, String plantId) => _firestore
      .collection('gardens')
      .doc(gardenId)
      .collection('plants')
      .doc(plantId)
      .collection('observations');

  Stream<List<ObservationMessage>> watchMessages(
    String gardenId,
    String plantId,
  ) {
    return messagesRef(gardenId, plantId)
        .orderBy('timestamp', descending: true)
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

  Future<void> addMessage(
    String gardenId,
    String plantId,
    ObservationMessage message,
  ) async {
    await messagesRef(gardenId, plantId).add(message.toMap());
  }

  Future<void> updateMessage(
    String gardenId,
    String plantId,
    ObservationMessage message,
  ) async {
    await messagesRef(
      gardenId,
      plantId,
    ).doc(message.id).update(message.toMap());
  }

  Future<void> deleteMessage(
    String gardenId,
    String plantId,
    String messageId,
  ) async {
    await messagesRef(gardenId, plantId).doc(messageId).delete();
  }
}
