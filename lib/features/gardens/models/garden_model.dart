import 'package:cloud_firestore/cloud_firestore.dart';

class Garden {
  final String id;
  final String name;
  final double width;
  final double length;
  final bool isPublic;
  final String ownerId;
  final DateTime createdAt;
  final bool isEditable;
  final List<String>? imageUrl;
  final String? ownerUsername;
  final String? backgroundType;
  final List<dynamic>? tilemap;
  final int? tilesWide;
  final int? tilesHigh;
  final double? tileSize;

  Garden({
    required this.id,
    required this.name,
    required this.width,
    required this.length,
    required this.isPublic,
    required this.ownerId,
    required this.createdAt,
    required this.isEditable,
    this.ownerUsername,
    this.imageUrl,
    this.backgroundType,
    this.tilemap,
    this.tilesHigh,
    this.tilesWide,
    this.tileSize,
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
      length: (data['length'] ?? 0).toDouble(),
      isPublic: data['isPublic'] ?? false,
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isEditable: data['isEditable'] ?? false,
      imageUrl: data['imageUrl'],
      ownerUsername: data['ownerUsername'] ?? '',
      backgroundType: data['backgroundType'],
      tilemap: data['tilemap'],
      tilesWide: data['tilesWide'],
      tilesHigh: data['tilesHigh'],
      tileSize: data['tileSize'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'width': width,
      'length': length,
      'isPublic': isPublic,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEditable': isEditable,
      'imageUrl': imageUrl,
      'ownerUsername': ownerUsername,
      'backgroundType': backgroundType,
      'tilemap': tilemap,
      'tilesWide': tilesWide,
      'tilesHigh': tilesHigh,
      'tileSize': tileSize,
    };
  }
}
