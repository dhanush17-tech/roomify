import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/onboarding/0_onboarding.dart';

import '../auth/login.dart';
import '1_onbroading.dart';
import '2_onbroading.dart';
import '3_onbroading.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Onboarding0(),
    Onboarding1(),
    Onboarding2(),
    Onboarding3()
  ];

  void _nextPage() {
    if (_currentIndex < _screens.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFFBFCFC),
      body: Stack(
        children: [
          // PageView constrained within a SizedBox
          Positioned.fill(
            // top: screenHeight * 0.15, // Leave space for the stepper
            // bottom: screenHeight * 0.15, // Leave space for the button
            child: SizedBox.expand(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _screens.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _screens[index];
                },
              ),
            ),
          ),

          // Stepper positioned at the top
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(_screens.length - 1);
                  },
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.zero, // Remove padding to keep layout intact
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ClipRect limits the blur to the button's area
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 20),
                            decoration: BoxDecoration(
                              color: _currentIndex == 0
                                  ? Colors.black.withOpacity(0.1)
                                  : orangeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: _currentIndex == 0
                                  ? Border.all(
                                      color: Color(
                                          0xFFECF0F1)) // White border for the first page
                                  : Border.all(color: Colors.transparent),
                            ),
                          ),
                        ),
                      ),
                      // Text is placed on top of the blurred background
                      Text(
                        'Skip',
                        style: AppTextStyles.button(
                            fontSize: 15, color: orangeColor),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_screens.length, (index) {
                    return Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: index <= _currentIndex
                            ? orangeColor
                            : _currentIndex == 0
                                ? Color(4294632915)
                                : orangeColor.withOpacity(0.1),
                      ),
                    );
                  }),
                ),
                SizedBox(
                    width: 48), // Placeholder for alignment with "Skip" button
              ],
            ),
          ),
          // Next or Get Started Button positioned at the bottom
          Positioned(
            bottom: screenHeight * 0.08,
            left: 0,
            right: 0,
            child: _currentIndex == _screens.length - 1
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => SignUpLoginScreen()),
                                  (route) => false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Get Started",
                              style: AppTextStyles.button(),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => SignUpLoginScreen()),
                                  (route) => false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 60, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Login",
                              style: AppTextStyles.button(color: orangeColor),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SocialIcon(
                              icon: "assets/icons/facebook_icon.svg",
                              color: orangeColor),
                          SizedBox(width: 40),
                          SocialIcon(
                              icon: "assets/icons/google_icon.svg",
                              color: orangeColor),
                          SizedBox(width: 40),
                          SocialIcon(
                            icon: "assets/icons/apple_icon.svg",
                            color: orangeColor,
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Next",
                        style: AppTextStyles.button(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper method to build social media icon containers

class SocialIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final isSvg;

  SocialIcon({required this.icon, this.color = orangeColor, this.isSvg = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      padding: EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: isSvg
            ? SvgPicture.asset(
                icon,
                color: this.color,
              )
            : Image.asset(
                icon,
                color: color,
                width: 20,
              ),
      ),
    );
  }
}
