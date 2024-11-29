import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:roomify_app/models/chatModel.dart';

class ChatRepository {
 
  Future<List<ChatRoom>> getChats() async {
    try {
      final token = await AuthRepository().getToken();

      Map<String, String> _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['rooms'];
        return data.map((room) => ChatRoom.fromJson(room)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load chats: $e');
    }
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      final token = await AuthRepository().getToken();

      Map<String, String> _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/$roomId/messages'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['messages'];
        List<ChatMessage> messages = data.map((msg) => ChatMessage.fromJson(msg)).toList();
        // Sort messages by creation time
        messages.sort((a, b) => a.compareTo(b));
        return messages;
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<WebSocketChannel> connectToRoom(String roomId) async {
    final token = await AuthRepository().getToken();
    print(token);
    // Convert HTTP URL to WebSocket URL correctly
    final wsUrl = '$baseUrl/api/chat/$roomId/ws'
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    final headers = {
      'Authorization': 'Bearer $token',
      'Connection': 'Upgrade',
      'Upgrade': 'websocket',
    };

    print('Connecting to WebSocket URL: $wsUrl'); // Debug log

    return IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: headers,
    );
  }

  Future<ChatRoom> createOrGetChatRoom(String otherUserId) async {
    try {
      final token = await AuthRepository().getToken();

      Map<String, String> _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/create'),
        headers: _headers,
        body: json.encode({'otherUserId': otherUserId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['room'];
        return ChatRoom.fromJson(data);
      } else {
        throw Exception('Failed to create chat room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }
}
