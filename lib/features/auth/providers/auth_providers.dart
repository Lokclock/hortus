import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/services/firebase_providers.dart';
import 'package:hortus_app/features/auth/data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(authProvider);
  return AuthService(auth);
});
