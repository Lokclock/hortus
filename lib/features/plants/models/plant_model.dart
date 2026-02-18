import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String id;
  final String gardenId;
  final String name;
  final double x;
  final double y;
  final String type;
  final DateTime? plantedAt;
  final DateTime? harvestAt;

  Plant({
    required this.id,
    required this.gardenId,
    required this.name,
    required this.x,
    required this.y,
    required this.type,
    this.plantedAt,
    this.harvestAt,
  });

  factory Plant.fromMap(Map<String, dynamic> data, String id) {
    return Plant(
      id: id,
      gardenId: data['gardenId'],
      name: data['name'],
      x: (data['x'] as num).toDouble(),
      y: (data['y'] as num).toDouble(),
      type: data['type'],
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
      'x': x,
      'y': y,
      'type': type,
      'plantedAt': plantedAt,
      'harvestAt': harvestAt,
    };
  }
}
