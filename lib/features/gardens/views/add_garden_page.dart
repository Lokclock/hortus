import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/core/services/firebase_providers.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';

class AddGardenPage extends ConsumerStatefulWidget {
  const AddGardenPage({super.key});

  @override
  ConsumerState<AddGardenPage> createState() => _AddGardenPageState();
}

class _AddGardenPageState extends ConsumerState<AddGardenPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final widthCtrl = TextEditingController();
  final lengthCtrl = TextEditingController();

  bool isPublic = false;
  bool isEditable = false;
  bool loading = false;

  Future<void> _createGarden({bool openEditor = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final uid = ref.read(currentUserProvider);
      if (uid == null) throw Exception("Utilisateur non connecté");

      final userDoc = await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(uid)
          .get();
      final username = userDoc.data()?['username'] ?? 'inconnu';

      // 🔹 Crée le jardin dans Firestore
      final docRef = await ref
          .read(gardenRepoProvider)
          .createGarden(
            name: nameCtrl.text.trim(),
            width: double.parse(widthCtrl.text),
            length: double.parse(lengthCtrl.text),
            isPublic: isPublic,
            isEditable: isPublic ? isEditable : false,
            ownerUsername: username,
          );

      final gardenId = docRef.id;

      if (openEditor) {
        if (mounted) {
          Navigator.pop(context);
          context.push('/tile_editor/$gardenId');
        }
      } else {
        if (mounted) context.push('/home');
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Créer un jardin", style: theme.textTheme.headlineSmall),

                const SizedBox(height: 24),

                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nom du jardin"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Obligatoire" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: widthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Largeur (m)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Obligatoire" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: lengthCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Longueur (m)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Obligatoire" : null,
                ),

                const SizedBox(height: 20),

                SwitchListTile(
                  title: const Text("Jardin public"),
                  value: isPublic,
                  onChanged: (v) => setState(() => isPublic = v),
                ),

                if (isPublic)
                  SwitchListTile(
                    title: const Text("Modifiable par tous"),
                    subtitle: const Text("Sinon lecture seule"),
                    value: isEditable,
                    onChanged: (v) => setState(() => isEditable = v),
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => _createGarden(openEditor: false),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Créer et importer une image"),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => _createGarden(openEditor: true),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Créer et ouvrir l’éditeur"),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _createGarden,
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Créer le jardin"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
