import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_textfield.dart';

class RegisterPage extends ConsumerWidget {
  RegisterPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                await auth.register(emailCtrl.text, passCtrl.text);
                Navigator.pop(context);
              },
              child: const Text("Créer le compte"),
            ),
          ],
        ),
      ),
    );
  }
}
