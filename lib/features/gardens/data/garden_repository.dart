import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hortus_app/features/gardens/models/garden_model.dart';
import 'package:hortus_app/features/map_editor/providers/tile_editor_notifier.dart';
import 'package:rxdart/rxdart.dart';

class GardenRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GardenRepository(this._firestore, this._auth);

  /// 🔹 Référence collection
  CollectionReference get _gardens => _firestore.collection('gardens');

  /// 🌱 Stream temps réel des jardins du user
  Stream<List<Garden>> watchUserGardens() {
    final uid = _auth.currentUser!.uid;

    return _gardens
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Garden.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList(),
        );
  }

  /// 🌍 Tous les jardins accessibles (perso + publics)
  Stream<List<Garden>> watchAccessibleGardens() {
    final uid = _auth.currentUser!.uid;

    final myGardensStream = _gardens
        .where('ownerId', isEqualTo: uid)
        .snapshots();

    final publicGardensStream = _gardens
        .where('isPublic', isEqualTo: true)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<Garden>>(
      myGardensStream,
      publicGardensStream,
      (mySnap, publicSnap) {
        final allDocs = [...mySnap.docs, ...publicSnap.docs];

        final gardens = allDocs
            .map(
              (doc) =>
                  Garden.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList();

        /// Supprime doublons si un jardin perso est aussi public
        final unique = {for (var g in gardens) g.id: g}.values.toList();

        unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return unique;
      },
    );
  }

  /// 🌿 Écoute d’un jardin spécifique
  Stream<Garden> watchGarden(String gardenId) {
    return _gardens.doc(gardenId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        throw Exception("Garden not found");
      }
      return Garden.fromMap(data as Map<String, dynamic>, doc.id);
    });
  }

  /// 🌿 Ajouter un jardin
  Future<DocumentReference> createGarden({
    required String name,
    required double width,
    required double length,
    required bool isPublic,
    required bool isEditable,
    required String ownerUsername,
    required List<List<TileType>> tiles,
  }) async {
    final uid = _auth.currentUser!.uid;

    // 🔹 Convertir les tiles en int ou String pour Firestore
    final flatTiles = tiles
        .expand((row) => row.map((t) => t.index)) // TileType → int
        .toList();

    final docRef = await _gardens.add({
      'name': name,
      'width': width,
      'length': length,
      'isPublic': isPublic,
      'isEditable': isEditable,
      'ownerId': uid,
      'ownerUsername': ownerUsername,
      'createdAt': FieldValue.serverTimestamp(),
      'tilemap': flatTiles, // List<int> aplati
      'tilesWide': tiles.first.length,
      'tilesHigh': tiles.length,
      'tileSize': 64.0,
    });

    return docRef; // <-- retourne le DocumentReference
  }

  /// 🪓 Supprimer un jardin
  Future<void> deleteGarden(String id) async {
    await _gardens.doc(id).delete();
  }

  /// 🔹 Update tilemap of a garden
  Future<void> updateGardenTilemap(
    String gardenId,
    Map<String, dynamic> tilemap,
  ) async {
    await _gardens.doc(gardenId).set({
      'backgroundType': 'tilemap',
      'tilemap': tilemap,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔹 Récupère un jardin une seule fois
  Future<Garden> getGardenOnce(String gardenId) async {
    final doc = await _gardens.doc(gardenId).get();
    final data = doc.data();
    if (data == null) {
      throw Exception("Garden not found");
    }
    return Garden.fromMap(data as Map<String, dynamic>, doc.id);
  }
}
