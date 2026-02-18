import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_textfield.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends ConsumerWidget {
  LoginPage({super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Connexion", style: TextStyle(fontSize: 32)),

            const SizedBox(height: 24),

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
                await auth.login(emailCtrl.text, passCtrl.text);
              },
              child: const Text("Se connecter"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterPage()),
                );
              },
              child: const Text("Créer un compte"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                );
              },
              child: const Text("Mot de passe oublié"),
            ),
          ],
        ),
      ),
    );
  }
}
