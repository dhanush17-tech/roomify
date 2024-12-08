import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/roommateMatch_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserMatchesScreen extends StatefulWidget {
  @override
  _UserMatchesScreenState createState() => _UserMatchesScreenState();
}

class _UserMatchesScreenState extends State<UserMatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoommateMatchProvider>().loadMutualMatches();
    });
  }

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
                'Your Matches',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Consumer<RoommateMatchProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(child: Text(provider.error!));
              }

              if (provider.mutualMatches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No matches yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                itemCount: provider.mutualMatches.length,
                itemBuilder: (context, index) {
                  final match = provider.mutualMatches[index];
                  return _buildMatchTile(match);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTile(User match) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: match.profilePhotoUrl != null
              ? CachedNetworkImageProvider(match.profilePhotoUrl!)
              : null,
          child:
              match.profilePhotoUrl == null ? Text(match.displayName[0]) : null,
        ),
        title: Text(
          match.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: match.university != null ? Text(match.university!) : null,
        trailing: ElevatedButton(
          onPressed: () => _startChat(context, match),
          style: ElevatedButton.styleFrom(
            backgroundColor: orangeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Chat',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _startChat(BuildContext context, User matchedUser) async {
    try {
      final chatRoom = await context
          .read<ChatProvider>()
          .createOrGetChatRoom(matchedUser.id);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatMessageScreen(room: chatRoom),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat')),
      );
    }
  }
}
