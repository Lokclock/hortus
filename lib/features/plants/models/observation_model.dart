import 'package:cloud_firestore/cloud_firestore.dart';

class ObservationMessage {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;

  ObservationMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
  });

  factory ObservationMessage.fromMap(Map<String, dynamic> data, String id) {
    return ObservationMessage(
      id: id,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      content: data['content'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
