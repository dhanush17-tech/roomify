import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final bool fromLeft;

  CircularRevealClipper({
    required this.fraction,
    this.fromLeft = true,
  });

  @override
  Path getClip(Size size) {
    final center = fromLeft 
        ? Offset(0, size.height / 2)
        : Offset(size.width, size.height / 2);
    
    final radius = math.sqrt(size.width * size.width + size.height * size.height);
    final currentRadius = radius * fraction;

    final path = Path();
    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: currentRadius,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
} 