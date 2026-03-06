import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortus_app/features/auth/providers/auth_providers.dart';
import 'package:hortus_app/features/plants/models/observation_model.dart';
import 'package:hortus_app/features/plants/providers/observation_provider.dart';

class ObservationsChatPage extends ConsumerStatefulWidget {
  final String plantId;
  const ObservationsChatPage({super.key, required this.plantId});

  @override
  ConsumerState<ObservationsChatPage> createState() =>
      _ObservationsChatPageState();
}

class _ObservationsChatPageState extends ConsumerState<ObservationsChatPage> {
  final TextEditingController _controller = TextEditingController();
  String? editingMessageId;

  void sendMessage() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null || _controller.text.trim().isEmpty) return;

    final repo = ref.read(observationRepoProvider);

    final newMessage = ObservationMessage(
      id: '', // Firestore générera l'ID
      userId: userId,
      userName: 'User $userId', // tu peux récupérer le nom réel
      content: _controller.text.trim(),
      timestamp: DateTime.now(),
    );

    await repo.addMessage(widget.plantId, newMessage);
    _controller.clear();
  }

  void updateMessage(String id, String newText) async {
    final repo = ref.read(observationRepoProvider);

    final messages = ref.read(messagesProvider(widget.plantId).future);
    final oldMessage = (await messages).firstWhere((m) => m.id == id);

    final updated = ObservationMessage(
      id: oldMessage.id,
      userId: oldMessage.userId,
      userName: oldMessage.userName,
      content: newText,
      timestamp: oldMessage.timestamp,
    );

    await repo.updateMessage(widget.plantId, updated);
    setState(() {
      editingMessageId = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.plantId));
    final currentUserId = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Observations")),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                reverse: true, // de bas en haut
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMine = msg.userId == currentUserId;
                  final isEditing = editingMessageId == msg.id;

                  return ListTile(
                    title: Text(
                      "${msg.userName} • ${msg.timestamp.day}/${msg.timestamp.month} ${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                    ),
                    subtitle: isEditing
                        ? TextField(
                            controller: _controller..text = msg.content,
                            onSubmitted: (val) => updateMessage(msg.id, val),
                          )
                        : Text(msg.content),
                    trailing: isMine
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                editingMessageId = msg.id;
                                _controller.text = msg.content;
                              });
                            },
                          )
                        : null,
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
                    controller: _controller,
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
