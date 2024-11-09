import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/auth/forgot_passoword.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';

import '../onboarding/main_onboarding.dart';

class SignUpLoginScreen extends StatefulWidget {
  @override
  _SignUpLoginScreenState createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Text(
                "Let’s Get Started",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // Tab Bar for Sign Up / Log In
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    dividerHeight: 0,
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: orangeColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: Colors.transparent, // Removes the thin line
                    labelColor: Colors.white,
                    unselectedLabelColor: orangeColor,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'Sign Up'),
                      Tab(text: 'Log In'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Sign Up Tab
                    ListView(
                      children: [
                        InputField(label: "Name"),
                        InputField(label: "Email"),
                        InputField(label: "Password", obscureText: true),
                        InputField(label: "College"),
                        InputField(label: "Preferred Location"),
                        SizedBox(height: 20),
                        // Sign Up Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (c) => MainScreen()),
                                (route) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Terms and Privacy Policy Text
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'By signing up, you agree to our ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: orangeColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: orangeColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            "Join Roomify in just a few clicks",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Social Media Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialIcon(icon: "assets/icons/facebook_icon.svg"),
                            SizedBox(width: 20),
                            SocialIcon(icon: "assets/icons/google_icon.svg"),
                            SizedBox(width: 20),
                            SocialIcon(icon: "assets/icons/apple_icon.svg"),
                          ],
                        ),
                      ],
                    ),
                    // Log In Tab
                    ListView(
                      children: [
                        InputField(label: "Email"),
                        InputField(label: "Password", obscureText: true),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => ForgotPasswordScreen()));
                          },
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text("Forgot Passoword?"),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        // Log In Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (c) => MainScreen()),
                                (route) => false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Log In",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            "Join Roomify in just a few clicks",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Social Media Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialIcon(icon: "assets/icons/facebook_icon.svg"),
                            SizedBox(width: 20),
                            SocialIcon(icon: "assets/icons/google_icon.svg"),
                            SizedBox(width: 20),
                            SocialIcon(icon: "assets/icons/apple_icon.svg"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String label;
  final bool obscureText;

  InputField({required this.label, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
