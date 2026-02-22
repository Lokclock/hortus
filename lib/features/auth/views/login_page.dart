import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_textfield.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    final auth = ref.read(authServiceProvider);

    setState(() => isLoading = true);

    try {
      await auth.loginWithUsername(
        usernameCtrl.text.trim(),
        passCtrl.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "H o r t u s",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),

            const SizedBox(height: 50),

            AuthTextField(controller: usernameCtrl, label: "Username"),

            const SizedBox(height: 16),

            AuthTextField(
              controller: passCtrl,
              label: "Mot de passe",
              obscure: true,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Se connecter"),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                context.push('/register');
              },
              child: const Text("Créer un compte"),
            ),

            TextButton(
              onPressed: () {
                context.push('/forgot');
              },
              child: const Text("Mot de passe oublié"),
            ),
          ],
        ),
      ),
    );
  }
}
