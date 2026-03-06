import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';
import 'package:hortus_app/features/plants/models/observation_model.dart';
import 'package:hortus_app/features/plants/providers/observation_provider.dart';
import 'package:intl/intl.dart';

class ObservationsChatPage extends ConsumerStatefulWidget {
  final String plantId;
  final String gardenId;
  const ObservationsChatPage({
    super.key,
    required this.plantId,
    required this.gardenId,
  });

  @override
  ConsumerState<ObservationsChatPage> createState() =>
      _ObservationsChatPageState();
}

class _ObservationsChatPageState extends ConsumerState<ObservationsChatPage> {
  // Déclare deux controllers
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  String? editingMessageId;

  void sendMessage() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null || _addController.text.trim().isEmpty) return;

    final repo = ref.read(observationRepoProvider);

    // 🔹 récupérer username depuis Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final userName = userDoc.data()?['username'] ?? 'Utilisateur';

    final newMessage = ObservationMessage(
      id: '',
      userId: userId,
      userName: userName,
      content: _addController.text.trim(),
      timestamp: DateTime.now(),
    );

    await repo.addMessage(widget.gardenId, widget.plantId, newMessage);

    _addController.clear();
  }

  void updateMessage(String id, String newText) async {
    final repo = ref.read(observationRepoProvider);
    final messages = ref.read(
      messagesProvider((
        gardenId: widget.gardenId,
        plantId: widget.plantId,
      )).future,
    );
    final oldMessage = (await messages).firstWhere((m) => m.id == id);

    final updated = ObservationMessage(
      id: oldMessage.id,
      userId: oldMessage.userId,
      userName: oldMessage.userName,
      content: newText,
      timestamp: oldMessage.timestamp,
    );

    await repo.updateMessage(widget.gardenId, widget.plantId, updated);
    setState(() {
      editingMessageId = null;
      _editController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      messagesProvider((gardenId: widget.gardenId, plantId: widget.plantId)),
    );
    final currentUserId = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Observations")),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMine = msg.userId == currentUserId;
                  final isEditing = editingMessageId == msg.id;
                  final formatted = DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(msg.timestamp);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${msg.userName} • $formatted",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Dismissible(
                          key: ValueKey(msg.id),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.only(left: 20),

                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart &&
                                isMine) {
                              // Swipe gauche → éditer
                              setState(() {
                                editingMessageId = msg.id;
                                _editController.text = msg.content;
                              });
                              return false; // ne supprime pas
                            } else if (direction ==
                                    DismissDirection.startToEnd &&
                                isMine) {
                              // Swipe droite → supprimer
                              final confirm = await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Supprimer le message ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                              );
                              return confirm;
                            }
                            return false;
                          },
                          onDismissed: (direction) async {
                            if (direction == DismissDirection.endToStart &&
                                isMine) {
                              final repo = ref.read(observationRepoProvider);
                              await repo.deleteMessage(
                                widget.gardenId,
                                widget.plantId,
                                msg.id,
                              );
                            }
                          },
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? Colors.green.shade200
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: isEditing
                                ? Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 280,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? Colors.green.shade200
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Stack(
                                      children: [
                                        // TextField prenant toute la largeur
                                        TextField(
                                          controller: _editController,
                                          autofocus: true,
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          maxLines: null,
                                          minLines: 1,
                                          textInputAction:
                                              TextInputAction.newline,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.only(
                                              left: 12,
                                              top: 12,
                                              bottom: 12,
                                              right:
                                                  40, // espace pour le bouton ✓
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    16,
                                                  ), // coins arrondis
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Bouton ✓ en bas à droite
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            ),
                                            onPressed: () {
                                              final newText = _editController
                                                  .text
                                                  .trim();
                                              if (newText.isNotEmpty) {
                                                updateMessage(msg.id, newText);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 280,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? Colors.green.shade200
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      msg.content,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization
                        .sentences, // majuscule automatique au début
                    maxLines: null, // permet plusieurs lignes
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter une observation...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
