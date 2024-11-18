import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/messaging/chat_screen.dart';

class MessageHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Chats", style: AppTextStyles.title()),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),
            Text("Recent Matches", style: AppTextStyles.subtitle()),
            SizedBox(height: 10),
            _buildRecentMatches(),
            SizedBox(height: 20),
            Text("Messages", style: AppTextStyles.subtitle()),
            SizedBox(height: 10),
            Expanded(child: _buildMessagesList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return ListView(
      children: [
        _buildMessageTile(
            "John Dushane", "is typing...", "10:32 PM", true, 1, context),
        _buildMessageTile("David Emmanuel", "Is the room still available? 🤔",
            "5:43 PM", false, 0, context),
        _buildMessageTile(
            "Akinola Bidemi",
            "Great! Feel free to reach out if...",
            "10:50 AM",
            true,
            0,
            context),
        _buildMessageTile("Blessing Okon", "I'd like to see the apartme...",
            "8:20 AM", false, 0, context),
        _buildMessageTile("Ahmed Ibrahim", "Can I bring my pet along?",
            "1:05 PM", false, 11, context),
        _buildMessageTile("Maryam Yusuf", "What's the nearest bus stop?",
            "11:58 AM", false, 0, context),
      ],
    );
  }

  _buildMessageTile(String name, String message, String time, bool isOnline,
      int unreadCount, BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (C) => ChatScreen()));
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(
                'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'), // Replace with actual image paths
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
      title: Text(name, style: AppTextStyles.subtitle(fontSize: 16)),
      subtitle: Text(
        message,
        style: TextStyle(color: unreadCount > 0 ? Colors.black : Colors.grey),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (unreadCount > 0)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadCount',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search messages...",
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.filter_list, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRecentMatches() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMatchAvatar("David E.",
              'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'),
          _buildMatchAvatar("Ahmed I.",
              'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'),
          _buildMatchAvatar("John D.",
              'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'),
          _buildMatchAvatar("Akinola B.",
              'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'),
          _buildMatchAvatar("Blessing O.",
              'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'),
        ],
      ),
    );
  }

  Widget _buildMatchAvatar(String name, String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                NetworkImage(imagePath), // Replace with actual image paths
          ),
          SizedBox(height: 4),
          Text(name, style: AppTextStyles.caption(fontSize: 12)),
        ],
      ),
    );
  }
}
