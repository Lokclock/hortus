import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hortus_app/features/gardens/models/garden_model.dart';
import 'package:hortus_app/features/gardens/providers/garden_providers.dart';

class GardenDetailsPage extends ConsumerWidget {
  final String gardenId;

  const GardenDetailsPage({super.key, required this.gardenId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(gardenProvider(gardenId));

    return Scaffold(
      body: SafeArea(
        child: gardenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Erreur: $e")),
          data: (garden) {
            return Column(
              children: [
                /// 🔝 HEADER
                _Header(garden: garden),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      /// 💬 OBSERVATIONS
                      _ObservationsCard(gardenId: gardenId),

                      const SizedBox(height: 24),

                      /// 🖼️ CARROUSEL IMAGES
                      _ImagesCarousel(garden: garden),

                      const SizedBox(height: 32),

                      _CreatedByCard(username: garden.ownerUsername),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Garden garden;

  const _Header({required this.garden});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),

          Expanded(
            child: Text(
              garden.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          /// ⚙️ SETTINGS
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/garden-settings/${garden.id}');
            },
          ),
        ],
      ),
    );
  }
}

class _ObservationsCard extends StatelessWidget {
  final String gardenId;

  const _ObservationsCard({required this.gardenId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/garden-chat/$gardenId');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.green.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, size: 32),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Observations",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Voir les messages et notes du jardin",
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ImagesCarousel extends StatelessWidget {
  final Garden garden;

  const _ImagesCarousel({required this.garden});

  @override
  Widget build(BuildContext context) {
    final images = garden.imageUrl ?? [];

    if (images.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.shade200,
        ),
        child: const Text("Aucune image"),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(images[i], width: 260, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}

class _CreatedByCard extends StatelessWidget {
  final String? username;

  const _CreatedByCard({this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 24, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Créé par : ${username ?? 'Inconnu'}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
