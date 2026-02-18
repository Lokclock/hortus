import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_textfield.dart';

class ForgotPasswordPage extends ConsumerWidget {
  ForgotPasswordPage({super.key});

  final emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AuthTextField(controller: emailCtrl, label: "Email"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await auth.resetPassword(emailCtrl.text);
                Navigator.pop(context);
              },
              child: const Text("Envoyer email"),
            ),
          ],
        ),
      ),
    );
  }
}
