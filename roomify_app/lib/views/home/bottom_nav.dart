import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/views/auth/login.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/marketplace/add_marketplace.dart';
import 'package:roomify_app/views/marketplace/marketplace_home.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/profile/profile_home.dart';
import 'package:roomify_app/views/property/add_property.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:roomify_app/views/onboarding/main_onboarding.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/widgets/chat_notification.dart';

class MainScreen extends StatefulWidget {
  double latitude;
  double longitude;
  MainScreen({required this.latitude, required this.longitude});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'chat') {
        _showChatNotification(message);
      }
    });
  }

  void _showChatNotification(RemoteMessage message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Extract chat data from message
    final senderId = message.data['senderId'];
    final senderName = message.data['senderName'];
    final senderProfilePic = message.data['profileImageUrl'];
    final messageText = message.notification?.body ?? '';
    final roomId = message.data['roomId'];

    // Check if current route is ChatMessageScreen with the same room
    bool isInChatScreen = false;
    if (message.data['recipientId'] != authProvider.user?.id) {
      Navigator.popUntil(context, (route) {
        if (route.settings.name == 'ChatMessageScreen') {
          final ChatMessageScreen screen =
              route.settings.arguments as ChatMessageScreen;
          isInChatScreen = screen.room.id == roomId;
          return true;
        }
        return true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Switch accounts to chat"),
        ),
      );
    }
    // Don't show notification if user is already in chat with sender
    if (isInChatScreen) return;

    final room = await chatProvider.createOrGetChatRoom(senderId);
    // Increment unread count
    chatProvider.incrementUnreadCount(room);

    // Show the notification dialog
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => ChatNotificationDialog(
        senderName: senderName,
        message: messageText,
        senderProfilePic: senderProfilePic,
        onTap: () async {
          Navigator.pop(context); // Dismiss the dialog
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

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'What would you like to add?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.home, color: Colors.orange),
                title: Text('Property'),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddPropertyScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.shopping_bag, color: Colors.orange),
                title: Text('Marketplace Item'),
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate to add marketplace item screen
                  // TODO: Replace with actual marketplace add screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddMarketplaceScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<AuthProvider>();

    // Check if user is null
    if (userProvider.user == null) {
      return SignUpLoginScreen(widget.latitude, widget.longitude);
    }

    final isProfessional = userProvider.user!.isProfessional;

    final List<Widget> _screens = isProfessional
        ? [
            HomeScreen(
              user: userProvider.user!,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
            ProfileHomeScreen(widget.latitude, widget.longitude),
          ]
        : [
            HomeScreen(
              user: userProvider.user!,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
            RoommateMatchScreen(
              widget.latitude,
              widget.longitude,
            ),
            Container(), // Empty container for center button
            MarketplaceHomeScreen(
              widget.latitude,
              widget.longitude,
            ),
            ProfileHomeScreen(widget.latitude, widget.longitude),
          ];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (isProfessional) {
            setState(() {
              _currentIndex = index;
            });
          } else {
            if (index == 2) {
              _showAddItemDialog();
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          }
        },
        items: isProfessional
            ? [
                _buildBottomNavItem("assets/icons/home.png", 0),
                _buildBottomNavItem("assets/icons/profile.png", 1),
              ]
            : [
                _buildBottomNavItem("assets/icons/home.png", 0),
                _buildBottomNavItem("assets/icons/roommate.png", 1),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  label: '',
                ),
                _buildBottomNavItem("assets/icons/marketplace.png", 3),
                _buildBottomNavItem("assets/icons/profile.png", 4),
              ],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(String iconPath, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? Colors.orange.withOpacity(0.1) // Selected indicator background
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          iconPath,
          color: _currentIndex == index ? Colors.orange : Colors.grey,
          width: 24,
          height: 24,
        ),
      ),
      label: '',
    );
  }
}
