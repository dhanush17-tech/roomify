import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomify_app/utils/colors.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF8F8F8),
                ),
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              SizedBox(width: 20),
              Text(
                'Messages',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (provider.rooms.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages here',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.all(16),
                itemCount: provider.rooms.length,
                itemBuilder: (context, index) {
                  final room = provider.rooms[index];
                  return _buildChatTile(room);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatRoom room) {
    final lastMessage = room.lastMessage;
    final currentUserId = context.read<AuthProvider>().user?.id;
    final otherUser = room.participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => room.participants[0],
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Hero(
          tag: 'profile-${room.id}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              image: otherUser.profilePhotoUrl != null
                  ? DecorationImage(
                      fit: BoxFit.cover,
                      image: CachedNetworkImageProvider(
                          otherUser.profilePhotoUrl!))
                  : null,
            ),
            child: otherUser.profilePhotoUrl == null
                ? Center(child: Text(otherUser.displayName[0]))
                : null,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherUser.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              lastMessage?.content ?? '',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(lastMessage?.createdAt ?? room.updatedAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            if (room.unreadCount > 0)
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: orangeColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  room.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Mark messages as read when entering the chat
          context.read<ChatProvider>().markMessagesAsRead(room.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatMessageScreen(room: room),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    }
    if (now.difference(time).inDays < 7) {
      return DateFormat('E').format(time); // Returns abbreviated day name
    }
    return DateFormat('MMM d').format(time);
  }
}
