import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

class Onboarding0 extends StatelessWidget {
  const Onboarding0({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage("assets/illustrations/onboarding_0.png"))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome to Roomify!",
                style: AppTextStyles.title(
                    color: const Color.fromARGB(255, 238, 138, 50),
                    fontSize: 35)),
            SizedBox(height: 10),
            Text(
                "Use our smart filters to find the perfect room based on location, budget and more.",
                style: AppTextStyles.subtitle(color: Colors.white)),
            SizedBox(height: 20),
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            // Filters (Location and Wifi)
          ],
        ),
      ),
    );
  }
}
