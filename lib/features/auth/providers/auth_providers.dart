import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/services/firebase_providers.dart';
import 'package:hortus_app/features/auth/data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(authProvider);
  return AuthService(auth);
});

/// Fournit l'UID de l'utilisateur connecté ou null si non connecté
final currentUserProvider = Provider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid;
});
