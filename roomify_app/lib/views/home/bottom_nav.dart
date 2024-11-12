import 'package:flutter/material.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/marketplace/marketplace_home.dart';
import 'package:roomify_app/views/profile/profile_home.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/property/explore_properties.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:roomify_app/views/home/search_screen.dart';
import 'package:roomify_app/views/onboarding/main_onboarding.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    RoommateMatchScreen(),
    ExplorePropertiesScreen(), // Placeholder for a roommate screen
    MarketplaceScreen(),
    ProfileScreen(), // Placeholder for an apartment screen
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '',
          ),
        ],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}
