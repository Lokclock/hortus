import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/core/services/firebase_providers.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';
import 'package:hortus_app/features/auth/providers/auth_state_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(authStateProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text("Erreur: $e"),
          data: (user) {
            if (user == null) {
              return const Text("Non connecté");
            }

            final usernameFuture = ref
                .read(firestoreProvider)
                .collection('users')
                .doc(user.uid)
                .get();

            return FutureBuilder(
              future: usernameFuture,
              builder: (context, snapshot) {
                String username = "Utilisateur";

                if (snapshot.hasData) {
                  username =
                      snapshot.data!.data()?['username'] ?? "Utilisateur";
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// HANDLE
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    /// TITLE
                    Text("Profil", style: theme.textTheme.headlineSmall),

                    const SizedBox(height: 32),

                    /// USERNAME CARD
                    _InfoCard(
                      icon: Icons.person,
                      label: "Username",
                      value: username,
                    ),

                    const SizedBox(height: 12),

                    /// EMAIL CARD
                    _InfoCard(
                      icon: Icons.email,
                      label: "Email",
                      value: user.email ?? "Non défini",
                    ),

                    const SizedBox(height: 30),

                    /// LOGOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Se déconnecter"),
                        onPressed: () {
                          ref.read(authServiceProvider).logout();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
