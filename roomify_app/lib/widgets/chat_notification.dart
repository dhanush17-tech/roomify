import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

class ChatNotificationDialog extends StatelessWidget {
  final String senderName;
  final String message;
  final String senderProfilePic;
  final VoidCallback onTap;

  const ChatNotificationDialog(
      {required this.senderName,
      required this.message,
      required this.onTap,
      required this.senderProfilePic});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
        child: Dismissible(
          key: Key('chat_notification'),
          direction: DismissDirection.up,
          onDismissed: (_) => Navigator.pop(context),
          child: GestureDetector(
            onTap: onTap,
            child: Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: blackTextColor.withOpacity(0.2),
                      spreadRadius: 40.0,
                      blurRadius: 100.0,
                      offset: Offset(10, 10),
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange,
                      backgroundImage: NetworkImage(senderProfilePic),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
