import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_textfield.dart';

class RegisterPage extends ConsumerWidget {
  RegisterPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AuthTextField(controller: usernameCtrl, label: "Username"),

            const SizedBox(height: 16),

            AuthTextField(controller: emailCtrl, label: "Email"),

            const SizedBox(height: 16),

            AuthTextField(
              controller: passCtrl,
              label: "Mot de passe",
              obscure: true,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                try {
                  await auth.register(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    username: usernameCtrl.text.trim(),
                  );

                  // redirection propre avec GoRouter
                  context.go('/login');
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text("Créer le compte"),
            ),
          ],
        ),
      ),
    );
  }
}
