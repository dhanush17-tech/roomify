import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                  'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?cs=srgb&dl=pexels-italo-melo-881954-2379004.jpg&fm=jpg'), // Replace with actual image path
              radius: 20,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Akinola Bidemi",
                    style: AppTextStyles.title(fontSize: 16)),
                Text("Online",
                    style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.phone, color: Colors.black),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: Icon(Icons.videocam, color: Colors.black),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Today",
                        style: AppTextStyles.caption(fontSize: 12)),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(child: _buildChatMessages()),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildMessageInputField(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView(
      children: [
        _buildReceivedMessage(
            "Hey Emeka! 👋 Thanks for reaching out. This apartment is still available. When would you like to schedule a viewing?",
            "10:30 AM"),
        _buildSentMessage(
            "Hi Akinola! I'm interested in the apartment. Could I arrange a viewing tomorrow around 2 PM?",
            "10:35 AM"),
        _buildReceivedMessage(
            "That works for me. I'll meet you at the property at 2 PM. Looking forward to showing you around!",
            "10:40 AM"),
        _buildSentMessage(
            "Perfect! Thanks, Akinola. I'll see you tomorrow at 2 PM.",
            "10:45 AM"),
      ],
    );
  }

  Widget _buildReceivedMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(message, style: TextStyle(color: Colors.black87)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child:
                Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSentMessage(String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(message, style: TextStyle(color: Colors.black87)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child:
                Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return SafeArea(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A2F3030), // 10% opacity of color #2F3030
              offset: Offset(0, 8),
              blurRadius: 48,
              spreadRadius: 0,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Type message...",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Image.asset("assets/icons/send.png"),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
