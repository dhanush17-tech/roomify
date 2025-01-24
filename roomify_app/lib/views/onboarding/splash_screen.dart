import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/views/auth/reset_password.dart';
import 'package:roomify_app/views/auth/login.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';
import 'package:roomify_app/views/onboarding/main_onboarding.dart';
import 'package:app_links/app_links.dart';

class SplashScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const SplashScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastLinearToSlowEaseIn,
    );

    Future.delayed(Duration(seconds: 1), () {
      _controller.forward();
    });

     delayedNavigation();
  }

 

  Future<void> delayedNavigation() async {
    await Future.delayed(Duration(seconds: 2));
    if (!mounted) return;

    await _checkAuth();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (c) => MainScreen(
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (c) => SignUpLoginScreen(
            widget.latitude,
            widget.longitude,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    final userProvider = context.read<AuthProvider>();
    try {
      final token = await AuthRepository().getToken();
      if (token != null) {
        await userProvider.loadUserProfile();
        if (mounted) {
          setState(() {
            isLoggedIn = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoggedIn = false;
        });
      }
      print('Auto-login failed: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
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
