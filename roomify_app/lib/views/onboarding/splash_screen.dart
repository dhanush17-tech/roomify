import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/auth/login.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';
import 'package:roomify_app/views/onboarding/main_onboarding.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Creates a pop-in effect
    );

    // Start the animation after a 2-second delay
    Future.delayed(Duration(milliseconds: 1500), () {
      _controller.forward();
    });
    delayedNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  delayedNavigation() {
    Future.delayed((Duration(seconds: 3)), () {
      return Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (c) => MainScreen()), (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // First screen (orange background)
            Container(
              color: Color(0xFFE67E22),
              child: Center(
                child: Image.asset(
                  "assets/logos/roomify_logo.png",
                  width: screenWidth - 150,
                  color: Colors.white,
                ),
              ),
            ),
            // Second screen with animation
            ClipPath(
              clipper: CircleRevealClipper(_animation.value),
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Image.asset(
                    "assets/logos/roomify_logo.png",
                    width: screenWidth - 150,
                    color: orangeColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  } 
}

class CircleRevealClipper extends CustomClipper<Path> {
  final double value;

  CircleRevealClipper(this.value);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.longestSide * value; // Expands across the full screen

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
