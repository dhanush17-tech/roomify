import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/repository/chat_repo.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  Map<String, List<ChatMessage>> _messages = {};
  List<ChatRoom> _rooms = [];
  Map<String, WebSocketChannel> _socketChannels = {};
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._repository) {
    // Initialize by loading chats
    loadChats().then((value) {
      // After loading chats, connect to all rooms
      for (var room in _rooms) {
        loadMessages(room.id);
        connectToRoom(room.id);
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

  Future<void> connectToRoom(String roomId) async {
    try {
      if (_socketChannels.containsKey(roomId)) {
        return;
      }

      final channel = await _repository.connectToRoom(roomId);
      _socketChannels[roomId] = channel;

      channel.stream.listen(
        (dynamic message) {
          try {
            final data = jsonDecode(message);
            // Check if the message has the expected structure
            if (data['type'] == 'message' && data['message'] != null) {
              final chatMessage = ChatMessage.fromJson(data['message']);
              _addMessage(roomId, chatMessage);
            }
          } catch (e) {
            print('Error parsing message: $e');
            _error = 'Error parsing message: $e';
            notifyListeners();
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _error = 'Connection error: $error';
          notifyListeners();
        },
        onDone: () {
          print('WebSocket connection closed');
          _socketChannels.remove(roomId);
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to connect to chat room: $e';
      notifyListeners();
    }
  }

  Future<void> sendMessage(String roomId, String content) async {
    try {
      final channel = _socketChannels[roomId];
      if (channel == null) {
        throw Exception('Not connected to room');
      }

      // Send message in the format expected by the server
      channel.sink.add(jsonEncode({
        'content': content,
        'roomId': roomId,
      }));
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _addMessage(String roomId, ChatMessage message) {
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }

    _messages[roomId]!.add(message);

    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final isMessageFromMe = message.senderId == message.sender?.id;

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
      final room = await _repository.createOrGetChatRoom(otherUserId);
      // Check if room already exists in _rooms
      final existingRoomIndex = _rooms.indexWhere((r) => r.id == room.id);
      if (existingRoomIndex == -1) {
        _rooms.add(room);
        notifyListeners();
      }
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
      // Update the local state
      final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        _rooms[roomIndex] = ChatRoom(
          id: _rooms[roomIndex].id,
          participants: _rooms[roomIndex].participants,
          lastMessage: _rooms[roomIndex].lastMessage,
          updatedAt: _rooms[roomIndex].updatedAt,
          unreadCount: 0, // Reset unread count
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

  @override
  void dispose() {
    // Close all WebSocket connections
    for (final channel in _socketChannels.values) {
      channel.sink.close();
    }
    _socketChannels.clear();
    super.dispose();
  }
}
