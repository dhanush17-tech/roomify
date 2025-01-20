import 'dart:convert';

import 'package:roomify_app/models/userModel.dart';

class ChatRoom {
  final String id;
  final List<User> participants;
  final ChatMessage? lastMessage;
  final DateTime updatedAt;
  int unreadCount;
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
  final String? documentRequestId;
  final List<DocumentType>? requestedDocuments;
  final List<String>? submittedDocuments;
  final String? documentRequestStatus;
  final bool isDeleted;
  final String type;
  final String? customDocumentName;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.roomId,
    required this.createdAt,
    this.sender,
    this.documentRequestId,
    this.requestedDocuments,
    this.submittedDocuments,
    this.documentRequestStatus,
    this.isDeleted = false,
    required this.type,
    this.customDocumentName,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    String? roomId,
    DateTime? createdAt,
    User? sender,
    String? documentRequestId,
    List<DocumentType>? requestedDocuments,
    List<String>? submittedDocuments,
    String? documentRequestStatus,
    bool? isDeleted,
    String? type,
    String? customDocumentName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      documentRequestId: documentRequestId ?? this.documentRequestId,
      requestedDocuments: requestedDocuments ?? this.requestedDocuments,
      submittedDocuments: submittedDocuments ?? this.submittedDocuments,
      documentRequestStatus:
          documentRequestStatus ?? this.documentRequestStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      type: type ?? this.type,
      customDocumentName: customDocumentName ?? this.customDocumentName,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<DocumentType>? requestedDocs;
    List<String>? submittedDocs;
    String? requestStatus;
    String? customDocName;

    if (json['documentRequest'] != null) {
      try {
        final docs =
            jsonDecode(json['documentRequest']['requestedDocuments'] as String);
        customDocName =
            json['documentRequest']['customDocumentName'] as String?;

        requestedDocs = (docs as List)
            .map((d) => DocumentType.values.firstWhere(
                  (e) =>
                      e.toString().split('.').last.toLowerCase() ==
                      d.toString().toLowerCase(),
                  orElse: () => DocumentType.Custom,
                ))
            .toList();

        requestStatus = json['documentRequest']['status'];
      } catch (e) {
        print('Error parsing document request: $e');
      }
    }

    if (json['documentSubmission'] != null) {
      try {
        final docs =
            jsonDecode(json['documentSubmission']['documents'] as String);
        submittedDocs = (docs as List).map((d) => d.toString()).toList();
      } catch (e) {
        print('Error parsing document submission: $e');
      }
    }

    return ChatMessage(
      id: json['id'],
      content: json['content'],
      senderId: json['senderId'],
      roomId: json['roomId'],
      createdAt: DateTime.parse(json['createdAt']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      documentRequestId: json['documentRequest']?['id'],
      requestedDocuments: requestedDocs,
      submittedDocuments: submittedDocs,
      documentRequestStatus: requestStatus,
      isDeleted: json['isDeleted'] ?? false,
      type: json['type'] ?? '',
      customDocumentName: customDocName,
    );
  }

  int compareTo(ChatMessage other) {
    return createdAt.compareTo(other.createdAt);
  }
}

enum DocumentType {
  Passport,
  DriverLicense,
  StudentId,
  BankStatement,
  EmploymentLetter,
  UtilityBill,
  Custom
}

class DocumentRequest {
  final String id;
  final String senderId;
  final String recipientId;
  final List<DocumentType> requestedDocuments;
  final DateTime createdAt;
  final String status; // pending, fulfilled, rejected
  final List<String>? submittedDocuments; // URLs of submitted documents

  DocumentRequest({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.requestedDocuments,
    required this.createdAt,
    required this.status,
    this.submittedDocuments,
  });
}
