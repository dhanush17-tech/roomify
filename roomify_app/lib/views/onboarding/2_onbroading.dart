import 'package:flutter/material.dart';
import 'package:roomify_app/utils/text_styles.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

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
              "Connect with students who match your lifestyle and preferences.",
              style: AppTextStyles.caption(fontSize: 16)),
          // Filters (Location and Wifi)

          Image.asset("assets/illustrations/onboarding_2.png")
        ],
      ),
    );
  }
}
