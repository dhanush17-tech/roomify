import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/repository/chat_repo.dart';
import 'dart:io';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  Map<String, List<ChatMessage>> _messages = {};
  List<ChatRoom> _rooms = [];
  Map<String, WebSocketChannel> _socketChannels = {};
  Map<String, bool> _isReconnecting = {};
  bool _isLoading = false;
  String? _error;
  final AuthProvider _authProvider;
  bool _disposed = false;

  ChatProvider(this._repository, this._authProvider) {
    loadChats().then((value) {
      for (var room in _rooms) {
        loadMessages(room.id);
      }
    });
  }

  List<ChatRoom> get rooms => _rooms;
  List<ChatMessage> getMessages(String roomId) => _messages[roomId] ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChats() async {
    try {
      _isLoading = true;
      notifyListeners();

      _rooms = await _repository.getChats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String roomId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final messages = await _repository.getMessages(roomId);
      _messages[roomId] = messages;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleWebSocketMessage(dynamic message, String roomId) {
    try {
      var data = jsonDecode(message);

      if (data is! Map<String, dynamic>) {
        data = jsonDecode(data);
      }

      final messageType = data['type'];

      if (messageType == 'ping') {
        _handlePing(data, roomId);
        return;
      }

      if (!data.containsKey('roomId')) {
        data['roomId'] = roomId;
      }
      switch (messageType) {
        case 'message':
          final messageData = data['message'];
          if (messageData != null && messageData['content'] != null) {
            final chatMessage = ChatMessage.fromJson(messageData);
            _addMessage(roomId, chatMessage);
            notifyListeners();
          }
          break;

        case 'document_request':
          final messageData = data['message'];
          if (messageData != null) {
            final chatMessage = ChatMessage.fromJson(messageData);
            _addMessage(roomId, chatMessage);
            notifyListeners();
          }
          break;

        case 'document_submission':
          final messageData = data['message'];
          if (messageData != null) {
            final originalRequestId = messageData['id'];
            final roomMessages = _messages[roomId];

            if (roomMessages != null) {
              final requestIndex =
                  roomMessages.indexWhere((m) => m.id == originalRequestId);
              if (requestIndex != -1) {
                // Create new document submission object
                final documentSubmission = DocumentSubmission(
                  id: messageData['documentSubmission']['id'],
                  messageId: originalRequestId,
                  requestId: messageData['documentSubmission']['requestId'],
                  documents: jsonEncode(
                      messageData['documentSubmission']['documents']),
                  createdAt: DateTime.parse(messageData['createdAt']),
                );

                // Update the existing message
                final updatedMessage = roomMessages[requestIndex].copyWith(
                  type: 'DOCUMENT_REQUEST',
                  documentRequest: DocumentRequest(
                    id: roomMessages[requestIndex].documentRequest!.id,
                    messageId: originalRequestId,
                    requestedDocuments: roomMessages[requestIndex]
                        .documentRequest!
                        .requestedDocuments,
                    status: 'FULFILLED',
                    recipientId:
                        roomMessages[requestIndex].documentRequest!.recipientId,
                    createdAt:
                        roomMessages[requestIndex].documentRequest!.createdAt,
                    customDocumentName: roomMessages[requestIndex]
                        .documentRequest!
                        .customDocumentName,
                  ),
                  documentSubmission: documentSubmission,
                );

                roomMessages[requestIndex] = updatedMessage;
                _updateRequestMessage(roomId, updatedMessage);
                notifyListeners();
              }
            }
          }
          break;
      }
    } catch (e) {
      print('Error parsing message: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void _handlePing(Map<String, dynamic> data, String roomId) {
    final channel = _socketChannels[roomId];
    if (channel != null) {
      channel.sink.add(jsonEncode({'type': 'pong'}));
    }
  }

  Future<void> connectToRoom(String roomId) async {
    if (_isReconnecting[roomId] == true) {
      return;
    }

    try {
      _isReconnecting[roomId] = true;

      if (_socketChannels.containsKey(roomId)) {
        await _socketChannels[roomId]?.sink.close();
        _socketChannels.remove(roomId);
      }

      final channel = await _repository.connectToRoom(roomId);
      _socketChannels[roomId] = channel;

      channel.stream.listen(
        (message) {
          print("This is the messageeeeee $message");
          _handleWebSocketMessage(message, roomId);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _error = 'Connection error: $error';
          _handleConnectionError(roomId);
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleConnectionClosed(roomId);
        },
        cancelOnError: false,
      );

      _isReconnecting[roomId] = false;
    } catch (e) {
      _error = 'Failed to connect to chat room: $e';
      _isReconnecting[roomId] = false;
      _scheduleReconnect(roomId);
      notifyListeners();
    }
  }

  void _handleConnectionError(String roomId) {
    _socketChannels.remove(roomId);
    _scheduleReconnect(roomId);
    notifyListeners();
  }

  void _handleConnectionClosed(String roomId) {
    _socketChannels.remove(roomId);
    _scheduleReconnect(roomId);
    notifyListeners();
  }

  void _scheduleReconnect(String roomId) {
    if (_isReconnecting[roomId] != true) {
      Future.delayed(Duration(seconds: 5), () {
        if (_socketChannels[roomId] == null) {
          connectToRoom(roomId);
        }
      });
    }
  }

  Future<void> sendMessage(String roomId, String content) async {
    ChatMessage? tempMessage;
    try {
      final currentUser = _authProvider.user;
      if (currentUser != null) {
        tempMessage = ChatMessage(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          type: 'TEXT',
          content: content,
          createdAt: DateTime.now(),
          roomId: roomId,
          senderId: currentUser.id,
          sender: currentUser,
        );
        _addMessage(roomId, tempMessage);
      }

      final channel = _socketChannels[roomId];
      if (channel == null) {
        throw Exception('Not connected to room');
      }

      // Send the actual message through WebSocket with the correct data structure
      final messageData = {
        'type': 'message',
        'roomId': roomId,
        'content': content,
      };
      channel.sink.add(jsonEncode(messageData));

      if (tempMessage != null) {
        final roomMessages = _messages[roomId];
        if (roomMessages != null) {
          roomMessages.removeWhere((m) => m.id == tempMessage!.id);
          notifyListeners();
        }
      }
    } catch (e) {
      if (tempMessage != null) {
        final roomMessages = _messages[roomId];
        if (roomMessages != null) {
          roomMessages.removeWhere((m) => m.id == tempMessage!.id);
          notifyListeners();
        }
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  void _addMessage(String roomId, ChatMessage message) {
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    _messages[roomId]!.add(message);
    // Sort messages by creation time
    _messages[roomId]!.sort((a, b) => a.compareTo(b));

    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final isMessageFromMe = message.senderId == _authProvider.user?.id;

      _rooms[roomIndex] = _rooms[roomIndex].copyWith(
        lastMessage: message,
        updatedAt: DateTime.now(),
        unreadCount: isMessageFromMe
            ? _rooms[roomIndex].unreadCount
            : _rooms[roomIndex].unreadCount + 1,
      );

      _rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    notifyListeners();
  }

  Future<ChatRoom> createOrGetChatRoom(String otherUserId) async {
    try {
      _isLoading = true;
      notifyListeners();
      final room = await _repository.createOrGetChatRoom(otherUserId);
      final existingRoomIndex = _rooms.indexWhere((r) => r.id == room.id);

      if (existingRoomIndex == -1) {
        _rooms.add(room);
        // Initialize WebSocket connection for new room
        await connectToRoom(room.id);
        // Load messages for new room
        await loadMessages(room.id);
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String roomId) async {
    try {
      await _repository.markMessagesAsRead(roomId);
      final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(
          unreadCount: 0,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void disconnectFromRoom(String roomId) {
    final channel = _socketChannels[roomId];
    if (channel != null) {
      channel.sink.close();
      _socketChannels.remove(roomId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final channel in _socketChannels.values) {
      channel.sink.close();
    }
    _socketChannels.clear();
    _isReconnecting.clear();
    super.dispose();
  }

  int getTotalUnreadCount() {
    return _rooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  Future<void> requestDocuments(String roomId, String recipientId,
      List<DocumentType> documents, BuildContext? context,
      {String? customDocumentName}) async {
    if (_disposed) return;

    try {
      final channel = _socketChannels[roomId];
      if (channel == null) throw Exception('Not connected to room');

      final documentStrings =
          documents.map((d) => d.toString().split('.').last).toList();

      // Include both roomId and content fields
      channel.sink.add(jsonEncode({
        'type': 'document_request',
        'roomId': roomId,
        'content': 'Document Request', // Add a content field
        'recipientId': recipientId,
        'documents': documentStrings,
        'customDocumentName': customDocumentName,
      }));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void incrementUnreadCount(ChatRoom room) {
    final roomIndex = _rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      _rooms[roomIndex] = _rooms[roomIndex].copyWith(
        unreadCount: _rooms[roomIndex].unreadCount + 1,
      );
      notifyListeners();
    }
  }

  Future<void> sendDocumentRequest(
    String roomId,
    String recipientId,
    List<DocumentType> documents, {
    String? customDocumentName,
  }) async {
    ChatMessage? tempMessage;
    try {
      final currentUser = _authProvider.user;
      if (currentUser != null) {
        final documentRequest = DocumentRequest(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          messageId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          requestedDocuments: jsonEncode(
              documents.map((d) => d.toString().split('.').last).toList()),
          status: 'PENDING',
          recipientId: recipientId,
          createdAt: DateTime.now(),
          customDocumentName: customDocumentName,
        );

        tempMessage = ChatMessage(
          id: documentRequest.messageId,
          type: 'DOCUMENT_REQUEST',
          content: 'Document Request',
          createdAt: DateTime.now(),
          roomId: roomId,
          senderId: currentUser.id,
          sender: currentUser,
          documentRequest: documentRequest,
        );
        _addMessage(roomId, tempMessage);
      }

      // Send request through WebSocket
      final channel = _socketChannels[roomId];
      if (channel == null) throw Exception('Not connected to room');

      final documentStrings =
          documents.map((d) => d.toString().split('.').last).toList();

      channel.sink.add(jsonEncode({
        'type': 'document_request',
        'roomId': roomId,
        'recipientId': recipientId,
        'documents': documentStrings,
        'customDocumentName': customDocumentName,
      }));

      // Replace temp message with server response in _handleWebSocketMessage
      if (tempMessage != null) {
        final roomMessages = _messages[roomId];
        if (roomMessages != null) {
          roomMessages.removeWhere((m) => m.id == tempMessage!.id);
          notifyListeners();
        }
      }
    } catch (e) {
      // Remove temporary message if it exists
      if (tempMessage != null) {
        final roomMessages = _messages[roomId];
        if (roomMessages != null) {
          roomMessages.removeWhere((m) => m.id == tempMessage!.id);
          notifyListeners();
        }
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> submitDocuments(
    String roomId,
    String messageId,
    List<File> documents,
  ) async {
    try {
      final documentUrls = await _repository.submitDocuments(
        roomId,
        messageId,
        documents,
      );

      final channel = _socketChannels[roomId];
      if (channel != null) {
        // Include both roomId and content fields
        channel.sink.add(jsonEncode({
          'type': 'document_submission',
          'roomId': roomId,
          'content': 'Document Submission', // Add a content field
          'requestId': messageId,
          'documents': documentUrls
        }));
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      await _repository.deleteMessage(roomId, messageId);

      final channel = _socketChannels[roomId];
      if (channel != null) {
        // Include both roomId and content fields
        channel.sink.add(jsonEncode({
          'type': 'message_deleted',
          'roomId': roomId,
          'content': 'Message Deleted', // Add a content field
          'messageId': messageId,
        }));
      }

      // Update local state
      final roomMessages = _messages[roomId];
      if (roomMessages != null) {
        final messageIndex = roomMessages.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          roomMessages.removeAt(messageIndex);
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDocumentRequest(
    String roomId,
    String messageId,
    String requestId,
  ) async {
    try {
      await _repository.deleteDocumentRequest(roomId, requestId);
      await deleteMessage(roomId, messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateRequestMessage(String roomId, ChatMessage updatedMessage) {
    if (_messages.containsKey(roomId)) {
      final roomMessages = _messages[roomId]!;
      final messageIndex =
          roomMessages.indexWhere((m) => m.id == updatedMessage.id);
      if (messageIndex != -1) {
        roomMessages[messageIndex] = updatedMessage;
        // Sort messages by creation time
        roomMessages.sort((a, b) => a.compareTo(b));
        notifyListeners();
      }
    }
  }
}
