import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';

final canEditGardenProvider = Provider.family<bool, String>((ref, gardenId) {
  final gardenAsync = ref.watch(gardenProvider(gardenId));
  final userId = ref.watch(currentUserProvider);

  return gardenAsync.maybeWhen(
    data: (garden) {
      if (userId == null) return false;

      // owner
      if (garden.ownerId == userId) return true;

      // public editable
      if (garden.isPublic && garden.isEditable) return true;

      return false;
    },
    orElse: () => false,
  );
});
