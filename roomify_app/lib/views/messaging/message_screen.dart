import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatMessageScreen extends StatefulWidget {
  final ChatRoom room;

  ChatMessageScreen({required this.room});

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final _messageController = TextEditingController();
  late User otherUser;

  @override
  void initState() {
    super.initState();
    final chatProvider = context.read<ChatProvider>();

    // Load existing messages and connect to WebSocket
    chatProvider.loadMessages(widget.room.id);
    chatProvider.connectToRoom(widget.room.id);

    final currentUserId = context.read<AuthProvider>().user?.id;
    otherUser = widget.room.participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => widget.room.participants[0],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(
            widget.room.id,
            _messageController.text,
          );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: otherUser.profilePhotoUrl != null
                  ? NetworkImage(otherUser.profilePhotoUrl!)
                  : null,
              radius: 20,
              child: otherUser.profilePhotoUrl == null
                  ? Text(otherUser.displayName[0])
                  : null,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser.displayName,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                // Text(
                //   'Online',
                //   style: TextStyle(color: Colors.grey, fontSize: 12),
                // ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.room.id);
                messages.sort((a, b) => a.compareTo(b));
                
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(messages[messages.length - 1 - index]);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isMe = message.sender?.id == context.read<AuthProvider>().user?.id;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.75, // Limit bubble width
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                timeago.format(message.createdAt, locale: 'en'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            color: Colors.blue,
            onPressed: () {
              if (_messageController.text.isNotEmpty) {
                context.read<ChatProvider>().sendMessage(
                      widget.room.id,
                      _messageController.text,
                    );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
