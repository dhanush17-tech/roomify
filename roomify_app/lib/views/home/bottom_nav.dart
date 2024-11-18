import 'package:flutter/material.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/views/auth/login.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/marketplace/marketplace_home.dart';
import 'package:roomify_app/views/profile/profile_home.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/property/explore_properties.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:roomify_app/views/home/search_screen.dart';
import 'package:roomify_app/views/onboarding/main_onboarding.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<AuthViewModel>();

    // Check if user is null
    if (userProvider.user == null) {
      // Redirect to login or show a message
      return SignUpLoginScreen(); // Replace with your login screen widget
    }

    final List<Widget> _screens = [
      HomeScreen(
        user: userProvider.user!,
      ),
      RoommateMatchScreen(),
      SearchScreen(), // Placeholder for a roommate screen
      MarketplaceScreen(),
      ProfileScreen(), // Placeholder for an apartment screen
    ];
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          _buildBottomNavItem("assets/icons/home.png", 0),
          _buildBottomNavItem("assets/icons/roommate.png", 1),
          _buildBottomNavItem("assets/icons/property.png", 2),
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
