import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final heightCtrl = TextEditingController();

  bool isPublic = false;
  bool isEditable = false;
  bool loading = false;

  Future<void> _createGarden() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    await ref
        .read(gardenRepoProvider)
        .createGarden(
          name: nameCtrl.text.trim(),
          width: double.parse(widthCtrl.text),
          height: double.parse(heightCtrl.text),
          isPublic: isPublic,
          isEditable: isPublic ? isEditable : false,
        );

    if (mounted) context.push('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Créer un jardin")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nom du jardin"),
                validator: (v) => v == null || v.isEmpty ? "Obligatoire" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: widthCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Largeur (m)"),
                validator: (v) => v == null || v.isEmpty ? "Obligatoire" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Hauteur (m)"),
                validator: (v) => v == null || v.isEmpty ? "Obligatoire" : null,
              ),

              const SizedBox(height: 20),

              /// PUBLIC SWITCH
              SwitchListTile(
                title: const Text("Jardin public"),
                value: isPublic,
                onChanged: (v) => setState(() => isPublic = v),
              ),

              /// OPTION EDITABLE (visible seulement si public)
              if (isPublic)
                SwitchListTile(
                  title: const Text("Modifiable par tous"),
                  subtitle: const Text("Sinon lecture seule"),
                  value: isEditable,
                  onChanged: (v) => setState(() => isEditable = v),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _createGarden,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text("Créer le jardin"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
