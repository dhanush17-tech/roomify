import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "No worries! Enter your email address or phone number below and we'll send you a code to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.05), // Tab Bar for Email / Phone
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerHeight: 0,
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
                      Tab(text: 'Email'),
                      Tab(text: 'Phone'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Email Tab
                    ListView(
                      children: [
                        InputField(label: "Email"),
                        SizedBox(height: 20),
                        // Recover Password Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => ResetPasswordScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Recover Password",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate back to Login screen
                            },
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: orangeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Phone Tab
                    ListView(
                      children: [
                        InputField(label: "Phone Number"),
                        SizedBox(height: 20),
                        // Recover Password Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => ResetPasswordScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Recover Password",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Navigate back to Login screen
                            },
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: orangeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

class ResetPasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Set a New Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Enter the code you received to update your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              InputField(label: "Enter Recovery Code"),
              InputField(label: "New Password", obscureText: true),
              InputField(label: "Confirm Password", obscureText: true),
              SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.05), // Update Password Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (c) => SignUpLoginScreen()),
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
                    "Update Password",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate back to Login screen
                  },
                  child: Text(
                    "Back to Login",
                    style: TextStyle(
                      color: orangeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
