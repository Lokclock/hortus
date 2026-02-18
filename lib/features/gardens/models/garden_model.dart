import 'package:cloud_firestore/cloud_firestore.dart';

class Garden {
  final String id;
  final String name;
  final double width;
  final double height;
  final bool isPublic;
  final String ownerId;
  final DateTime createdAt;
  final bool isEditable;

  Garden({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.isPublic,
    required this.ownerId,
    required this.createdAt,
    required this.isEditable,
  });

  bool canEdit(String uid) {
    if (ownerId == uid) return true;
    if (isPublic && isEditable) return true;
    return false;
  }

  factory Garden.fromMap(Map<String, dynamic> data, String id) {
    return Garden(
      id: id,
      name: data['name'] ?? '',
      width: (data['width'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      isPublic: data['isPublic'] ?? false,
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isEditable: data['isEditable'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'width': width,
      'height': height,
      'isPublic': isPublic,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEditable': isEditable,
    };
  }
}
