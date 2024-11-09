import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Discover Rooms Based on Your Preferences",
              style: AppTextStyles.title()),
          SizedBox(height: 10),
          Text(
              "Use our smart filters to find the perfect room based on location, budget and more.",
              style: AppTextStyles.caption(fontSize: 16)),
          SizedBox(height: 20),
          // Filters (Location and Wifi)
          Image.asset("assets/illustrations/onboarding_1.png")
        ],
      ),
    );
  }
}
