import 'package:roomify_app/models/userModel.dart';

class ChatRoom {
  final String id;
  final List<User> participants;
  final ChatMessage? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  ChatRoom copyWith({
    String? id,
    List<User>? participants,
    ChatMessage? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      participants: (json['participants'] as List)
          .map((p) => User.fromJson(p['user']))
          .toList(),
      lastMessage: json['messages']?.isNotEmpty
          ? ChatMessage.fromJson(json['messages'][0])
          : null,
      updatedAt: DateTime.parse(json['updatedAt']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String roomId;
  final DateTime createdAt;
  final User? sender;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.roomId,
    required this.createdAt,
    this.sender,
  });

  int compareTo(ChatMessage other) {
    return createdAt.compareTo(other.createdAt);
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      senderId: json['senderId'],
      roomId: json['roomId'],
      createdAt: DateTime.parse(json['createdAt']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    );
  }
}
