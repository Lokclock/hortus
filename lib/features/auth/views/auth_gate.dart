import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_state_provider.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),

      data: (user) {
        // 🔹 utilisateur connecté
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });
        }
        // 🔹 pas connecté
        else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
        }

        return const SizedBox.shrink();
      },
    );
  }
}
