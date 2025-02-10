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

class DocumentRequest {
  final String id;
  final String messageId;
  final String requestedDocuments;
  final String status;
  final String recipientId;
  final DateTime createdAt;
  final String? customDocumentName;
  final User? recipient;

  DocumentRequest({
    required this.id,
    required this.messageId,
    required this.requestedDocuments,
    required this.status,
    required this.recipientId,
    required this.createdAt,
    this.customDocumentName,
    this.recipient,
  });

  factory DocumentRequest.fromJson(Map<String, dynamic> json) {
    return DocumentRequest(
      id: json['id'],
      messageId: json['messageId'],
      requestedDocuments: json['requestedDocuments'],
      status: json['status'],
      recipientId: json['recipientId'],
      createdAt: DateTime.parse(json['createdAt']),
      customDocumentName: json['customDocumentName'],
      recipient:
          json['recipient'] != null ? User.fromJson(json['recipient']) : null,
    );
  }
}

class DocumentSubmission {
  final String id;
  final String messageId;
  final String requestId;
  final String documents;
  final DateTime createdAt;

  DocumentSubmission({
    required this.id,
    required this.messageId,
    required this.requestId,
    required this.documents,
    required this.createdAt,
  });

  factory DocumentSubmission.fromJson(Map<String, dynamic> json) {
    return DocumentSubmission(
      id: json['id'],
      messageId: json['messageId'],
      requestId: json['requestId'],
      documents: json['documents'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ChatMessage {
  final String id;
  final String type;
  final String content;
  final DateTime createdAt;
  final String roomId;
  final String senderId;
  final bool isDeleted;
  final User? sender;
  final DocumentRequest? documentRequest;
  final DocumentSubmission? documentSubmission;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.roomId,
    required this.senderId,
    this.isDeleted = false,
    this.sender,
    this.documentRequest,
    this.documentSubmission,
  });

  List<DocumentType>? get requestedDocuments {
    if (documentRequest == null) return null;
    try {
      final docs = jsonDecode(documentRequest!.requestedDocuments) as List;
      return docs
          .map((d) => DocumentType.values.firstWhere(
                (e) =>
                    e.toString().split('.').last.toLowerCase() ==
                    d.toString().toLowerCase(),
                orElse: () => DocumentType.Custom,
              ))
          .toList();
    } catch (e) {
      print('Error parsing requested documents: $e');
      return null;
    }
  }

  List<String>? get submittedDocuments {
    if (documentSubmission == null) return null;
    try {
      final docs = jsonDecode(documentSubmission!.documents) as List;
      return docs.map((d) => d.toString()).toList();
    } catch (e) {
      print('Error parsing submitted documents: $e');
      return null;
    }
  }

  String? get documentRequestStatus => documentRequest?.status;
  String? get documentRequestId => documentRequest?.id;
  String? get customDocumentName => documentRequest?.customDocumentName;

  ChatMessage copyWith({
    String? id,
    String? type,
    String? content,
    DateTime? createdAt,
    String? roomId,
    String? senderId,
    bool? isDeleted,
    User? sender,
    DocumentRequest? documentRequest,
    DocumentSubmission? documentSubmission,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      isDeleted: isDeleted ?? this.isDeleted,
      sender: sender ?? this.sender,
      documentRequest: documentRequest ?? this.documentRequest,
      documentSubmission: documentSubmission ?? this.documentSubmission,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    json = json['message'] ?? json;
    return ChatMessage(
      id: json['id'],
      type: json['type'] ?? '',
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      roomId: json['roomId'],
      senderId: json['senderId'],
      isDeleted: json['isDeleted'] ?? false,
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      documentRequest: json['documentRequest'] != null
          ? DocumentRequest.fromJson(json['documentRequest'])
          : null,
      documentSubmission: json['documentSubmission'] != null
          ? DocumentSubmission.fromJson(json['documentSubmission'])
          : null,
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
