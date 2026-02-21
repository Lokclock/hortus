import 'package:flutter/material.dart';

class GardenChatPage extends StatelessWidget {
  final String gardenId;

  const GardenChatPage({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Observations")),
      body: Column(
        children: [
          const Expanded(child: Center(child: Text("Liste des messages ici"))),

          /// INPUT CHAT
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Écrire une observation...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
