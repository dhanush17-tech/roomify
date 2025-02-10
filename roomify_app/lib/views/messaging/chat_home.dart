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

class ChatHome extends StatefulWidget {
  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ChatRoom> _previousRooms = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF8F8F8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: blackTextColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 20),
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: blackTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (provider.rooms.isEmpty) {
                    return Center(
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
                    );
                  }

                  // Sort rooms by updatedAt in descending order
                  final sortedRooms = List<ChatRoom>.from(provider.rooms)
                    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                  // Handle room reordering animations
                  if (_previousRooms.isNotEmpty) {
                    for (var i = 0; i < sortedRooms.length; i++) {
                      final room = sortedRooms[i];
                      final oldIndex =
                          _previousRooms.indexWhere((r) => r.id == room.id);
                      if (oldIndex != -1 && oldIndex != i) {
                        // Room position has changed, animate it
                        _listKey.currentState?.removeItem(
                          oldIndex,
                          (context, animation) => SizeTransition(
                            sizeFactor: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: _buildChatTile(_previousRooms[oldIndex]),
                            ),
                          ),
                        );
                        _listKey.currentState?.insertItem(i);
                      }
                    }
                  }

                  _previousRooms = List.from(sortedRooms);

                  return AnimatedList(
                    key: _listKey,
                    initialItemCount: sortedRooms.length,
                    padding: EdgeInsets.only(left: 16, right: 16),
                    itemBuilder: (context, index, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: _buildChatTile(sortedRooms[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
            color: blackTextColor.withOpacity(0.05),
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
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: otherUser.profilePhotoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: otherUser.profilePhotoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person,
                            color: Colors.grey[400], size: 30),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person,
                            color: Colors.grey[400], size: 30),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.person, color: Colors.grey[400], size: 30),
                    ),
            ),
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
          // Navigate first, without marking messages as read
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatMessageScreen(room: room),
              settings: RouteSettings(
                name: 'ChatMessageScreen',
                arguments: ChatMessageScreen(room: room),
              ),
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
