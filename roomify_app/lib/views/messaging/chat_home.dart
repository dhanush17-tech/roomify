import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Chats', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Matches Section
              // Padding(
              //   padding: EdgeInsets.all(16),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'Recent Matches',
              //         style: TextStyle(
              //           fontSize: 16,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       SizedBox(height: 16),
              //       SingleChildScrollView(
              //         scrollDirection: Axis.horizontal,
              //         child: Row(
              //           children: provider.recentMatches.map((user) {
              //             return _buildRecentMatch(user);
              //           }).toList(),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Messages Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: provider.rooms.length,
                  itemBuilder: (context, index) {
                    final room = provider.rooms[index];
                    return _buildChatTile(room);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentMatch(User user) {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user.profilePhotoUrl != null
                ? NetworkImage(user.profilePhotoUrl!)
                : null,
            child:
                user.profilePhotoUrl == null ? Text(user.displayName[0]) : null,
          ),
          SizedBox(height: 8),
          Text(
            user.displayName.split(' ')[0],
            style: TextStyle(fontSize: 12),
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

    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: otherUser.profilePhotoUrl != null
            ? NetworkImage(otherUser.profilePhotoUrl!)
            : null,
        child: otherUser.profilePhotoUrl == null
            ? Text(otherUser.displayName[0])
            : null,
      ),
      title: Text(
        otherUser.displayName,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        lastMessage?.content ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(lastMessage?.createdAt ?? room.updatedAt),
        style: TextStyle(color: Colors.grey),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatMessageScreen(room: room),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return DateFormat('h:mm a').format(time);
    }
    return DateFormat('MMM d').format(time);
  }
}
