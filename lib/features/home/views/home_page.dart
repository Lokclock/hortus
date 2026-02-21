import 'package:flutter/material.dart';
import '../../gardens/views/gardens_page.dart';
import '../../gardens/views/add_garden_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openSheet(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            SingleChildScrollView(controller: controller, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: const GardensPage(),

      /// 🔹 FLOATING ACTION BAR
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// PROFIL
            IconButton(
              icon: Icon(Icons.person, color: theme.colorScheme.primary),
              onPressed: () => _openSheet(context, const ProfilePage()),
            ),

            const SizedBox(width: 12),

            /// ADD GARDEN (bouton central)
            IconButton(
              onPressed: () => _openSheet(context, const AddGardenPage()),
              icon: Icon(Icons.add, color: theme.colorScheme.primary),
            ),

            const SizedBox(width: 12),

            /// PARAMETRES
            IconButton(
              icon: Icon(Icons.settings, color: theme.colorScheme.primary),
              onPressed: () => _openSheet(context, const _SettingsSheet()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Paramètres", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Mode sombre"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Se déconnecter"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
