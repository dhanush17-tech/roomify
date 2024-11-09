import 'package:flutter/material.dart';
import 'package:roomify_app/utils/text_styles.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

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
          Text("Find essential items or sell what you don’t need.",
              style: AppTextStyles.caption(fontSize: 16)),
          SizedBox(height: 20),
          // Filters (Location and Wifi)
          Image.asset("assets/illustrations/onboarding_3.png")
        ],
      ),
    );
  }
}
