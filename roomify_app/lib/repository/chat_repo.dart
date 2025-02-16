import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'dart:io';

class ChatRepository {
  /// Loads the list of chats for the current user
  ///
  /// Throws an [Exception] if the request fails
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
        List<ChatMessage> messages =
            data.map((msg) => ChatMessage.fromJson(msg)).toList();
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
    final wsUrl = '$baseUrl/api/chat/$roomId/ws'
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    final headers = {
      'Authorization': 'Bearer $token',
      'Connection': 'Upgrade',
      'Upgrade': 'websocket',
    };

    try {
      final channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: headers,
        pingInterval: Duration(seconds: 15),
        connectTimeout: Duration(seconds: 10),
      );

      // Add connection monitoring
      channel.stream.handleError((error) {
        print('WebSocket error: $error');
        throw Exception('WebSocket connection error: $error');
      });

      return channel;
    } catch (e) {
      throw Exception('Failed to connect to chat room: $e');
    }
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
        final room = ChatRoom.fromJson(data);
        return room;
      } else {
        throw Exception('Failed to create chat room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> markMessagesAsRead(String roomId) async {
    try {
      final token = await AuthRepository().getToken();

      Map<String, String> _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/$roomId/mark-read'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<ChatMessage?> requestDocuments(
    String roomId,
    String recipientId,
    List<DocumentType> documents, {
    String? customDocumentName,
  }) async {
    try {
      final token = await AuthRepository().getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      if (documents.isEmpty) {
        throw Exception('No documents selected');
      }

      final documentStrings = documents.map((d) => d.name).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/$roomId/request-document'),
        headers: headers,
        body: json.encode({
          'recipientId': recipientId,
          'requestedDocuments': documentStrings,
          'customDocumentName': customDocumentName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request documents: ${response.statusCode}');
      }
      return ChatMessage.fromJson(json.decode(response.body));
    } catch (e) {
      throw Exception('Failed to request documents: $e');
    }
  }

  Future<List<String>> submitDocuments(
    String roomId,
    String messageId,
    List<File> documents,
  ) async {
    try {
      final token = await AuthRepository().getToken();

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/chat/$roomId/submit-document'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add requestId as a field
      request.fields['requestId'] = messageId;

      // Add all documents
      for (var document in documents) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'documents', // Match the field name expected by backend
            document.path,
            filename: document.path.split('/').last,
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Failed to submit documents: ${response.statusCode}');
      }

      // Parse response to get document URLs
      final responseData = json.decode(response.body);
      if (responseData['documentUrls'] != null) {
        return List<String>.from(responseData['documentUrls']);
      }
      throw Exception('No document URLs returned from server');
    } catch (e) {
      throw Exception('Failed to submit documents: $e');
    }
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      final token = await AuthRepository().getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/$roomId/messages/$messageId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'];
        throw Exception(
            error ?? 'Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> deleteDocumentRequest(String roomId, String requestId) async {
    try {
      final token = await AuthRepository().getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/$roomId/document-requests/$requestId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete document request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete document request: $e');
    }
  }
}
