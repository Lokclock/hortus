import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/plants/models/plant_model.dart';

final selectedPlantProvider = StateProvider<Plant?>((ref) => null);
