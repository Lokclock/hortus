import 'package:flutter/material.dart';

class PlantEditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PlantEditButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        label: const Text('Déplacer'),
      ),
    );
  }
}
