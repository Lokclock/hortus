import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/auth/providers/auth_state_provider.dart';

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this.ref) {
    ref.listen(authStateProvider, (_, __) {
      notifyListeners(); // 🔥 dit au router de refresh
    });
  }

  final Ref ref;
}
