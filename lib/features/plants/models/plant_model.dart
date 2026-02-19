import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Plant {
  final String id;
  final String gardenId;

  final String name;
  final String? scientificName;
  final String? variety;

  final double x;
  final double y;

  final double diameter;
  final String icon;
  final String strate;
  final DateTime plantedAt;

  final Map<String, DateTimeRange?>? harvestType;
  final String? imageUrl;
  final List<Map<String, dynamic>>? observations;
  final List<String>? images;

  Plant({
    required this.id,
    required this.gardenId,
    required this.name,
    this.scientificName,
    this.variety,
    required this.x,
    required this.y,
    required this.diameter,
    required this.icon,
    required this.strate,
    required this.plantedAt,
    this.harvestType,
    this.imageUrl,
    this.observations,
    this.images,
  });

  // ================= FROM MAP =================

  factory Plant.fromMap(Map<String, dynamic> data, String id) {
    Map<String, DateTimeRange?>? harvestType;

    if (data['harvestType'] != null) {
      harvestType = {};

      (data['harvestType'] as Map<String, dynamic>).forEach((key, value) {
        if (value == null) {
          harvestType![key] = null;
        } else {
          harvestType![key] = DateTimeRange(
            start: (value['start'] as Timestamp).toDate(),
            end: (value['end'] as Timestamp).toDate(),
          );
        }
      });
    }

    return Plant(
      id: id,
      gardenId: data['gardenId'] ?? "",

      name: data['name'] ?? "",

      scientificName: data['scientificName'],
      variety: data['variety'],

      // SAFE conversion
      x: (data['x'] as num?)?.toDouble() ?? 0,
      y: (data['y'] as num?)?.toDouble() ?? 0,

      diameter: (data['diameter'] as num?)?.toDouble() ?? 0,

      icon: data['icon'] ?? "",
      strate: data['strate'] ?? "",

      plantedAt: (data['plantedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      harvestType: harvestType,
      imageUrl: data['imageUrl'],
      observations: data['observations'] as List<Map<String, dynamic>>?,
      images: data['images'] != null ? List<String>.from(data['images']) : null,
    );
  }

  // ================= TO MAP =================

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? harvestMap;

    if (harvestType != null) {
      harvestMap = {};

      harvestType!.forEach((key, range) {
        if (range == null) {
          harvestMap![key] = null;
        } else {
          harvestMap![key] = {
            "start": Timestamp.fromDate(range.start),
            "end": Timestamp.fromDate(range.end),
          };
        }
      });
    }

    return {
      'gardenId': gardenId,
      'name': name,
      'scientificName': scientificName,
      'variety': variety,
      'x': x,
      'y': y,
      'diameter': diameter,
      'icon': icon,
      'strate': strate,
      'plantedAt': Timestamp.fromDate(plantedAt),
      'harvestType': harvestMap,
      'imageUrl': imageUrl,
      'observations': observations,
      'images': images,
    };
  }
}
