import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String gardenId;
  final String name; // anciennement name commun
  final String? commonName;
  final String? scientificName;
  final String? variety;
  final double x;
  final double y;
  final double? diameter;
  final String type;
  final String? imageUrl;
  final List<String>? images;
  final String? harvestType;
  final String? strate;
  final List<Map<String, dynamic>>? observations; // {text, date}
  final DateTime? plantedAt;
  final DateTime? harvestAt;

  Plant({
    required this.id,
    required this.gardenId,
    required this.name,
    this.commonName,
    this.scientificName,
    this.variety,
    required this.x,
    required this.y,
    this.diameter,
    required this.type,
    this.imageUrl,
    this.images,
    this.harvestType,
    this.strate,
    this.observations,
    this.plantedAt,
    this.harvestAt,
  });

  factory Plant.fromMap(Map<String, dynamic> data, String id) {
    return Plant(
      id: id,
      gardenId: data['gardenId'],
      name: data['name'],
      commonName: data['commonName'],
      scientificName: data['scientificName'],
      variety: data['variety'],
      x: (data['x'] as num).toDouble(),
      y: (data['y'] as num).toDouble(),
      diameter: data['diameter'] != null
          ? (data['diameter'] as num).toDouble()
          : null,
      type: data['type'],
      imageUrl: data['imageUrl'],
      images: (data['images'] as List?)?.map((e) => e.toString()).toList(),
      harvestType: data['harvestType'],
      strate: data['strate'],
      observations: (data['observations'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList(),
      plantedAt: data['plantedAt'] != null
          ? (data['plantedAt'] as Timestamp).toDate()
          : null,
      harvestAt: data['harvestAt'] != null
          ? (data['harvestAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gardenId': gardenId,
      'name': name,
      'commonName': commonName,
      'scientificName': scientificName,
      'variety': variety,
      'x': x,
      'y': y,
      'diameter': diameter,
      'type': type,
      'imageUrl': imageUrl,
      'images': images,
      'harvestType': harvestType,
      'strate': strate,
      'observations': observations,
      'plantedAt': plantedAt,
      'harvestAt': harvestAt,
    };
  }
}
