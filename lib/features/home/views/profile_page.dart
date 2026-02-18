import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ref.read(authServiceProvider).logout();
          },
          child: const Text("Se déconnecter"),
        ),
      ),
    );
  }
}
