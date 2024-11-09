import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

import 'views/onboarding/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: orangeColor)),
      debugShowCheckedModeBanner: false,
      home: Material(color: Color(4294375672), child: SplashScreen()),
    );
  }
}
