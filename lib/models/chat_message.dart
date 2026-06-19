import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String? text;
  final String? reaction; // '👏' | '😤' | '😱' | '🔥' | '💔'
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    this.text,
    this.reaction,
    required this.createdAt,
  });

  bool get isReactionOnly => text == null || text!.isEmpty;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Torcedor',
      text: map['text'] as String?,
      reaction: map['reaction'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      if (text != null && text!.isNotEmpty) 'text': text,
      if (reaction != null) 'reaction': reaction,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
