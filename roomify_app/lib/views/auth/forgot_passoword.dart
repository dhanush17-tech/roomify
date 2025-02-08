import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils/colors.dart';

import 'login.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(builder: (context, provider, w) {
        if (provider.error == "Email Failed") {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Failed to send email")));
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child:
                Consumer<AuthProvider>(builder: (context, authProvider, child) {
              return Column(
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
                        indicatorColor:
                            Colors.transparent, // Removes the thin line
                        labelColor: Colors.white,
                        unselectedLabelColor: orangeColor.withOpacity(0.5),
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: 'Enter your Email'),
                          // Tab(text: 'Phone'),
                        ],
                      ),
                    ),
                  ),
                  if (authProvider.isEmailSent == true ||
                      authProvider.error != null) ...[
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: authProvider.error != null
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              authProvider.error != null
                                  ? Icons.error
                                  : Icons.check_circle,
                              color: authProvider.error != null
                                  ? Colors.red
                                  : Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authProvider.error == "Email Not Found"
                                  ? "No account found with this email address. Please check and try again."
                                  : authProvider.error == "Email Failed"
                                      ? "Failed to send recovery email. Please try again."
                                      : "The recovery email has been sent successfully! Please check your inbox.",
                              style: TextStyle(
                                color: authProvider.error != null
                                    ? Colors.red
                                    : Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ] else
                    SizedBox.shrink(),
                  SizedBox(height: 20),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Email Tab
                        ListView(
                          children: [
                            InputField(
                                controller: emailController, label: "Email"),
                            SizedBox(height: 20),

                            // Recover Password Button
                            ElevatedButton(
                              onPressed: () async {
                                if (emailController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Please enter your email address",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                await provider.requestPassswordReset(
                                    emailController.text, () {
                                  if (provider.error == null) {
                                    emailController.clear();
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: provider.isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
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
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      }),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final double latitude;
  final double longitude;

  const ResetPasswordScreen(this.token, this.latitude, this.longitude);

  // Add a static method to handle deep links
  static Route<dynamic> handleDeepLink(
      Uri uri, double latitude, double longitude) {
    final token = uri.queryParameters['token'];
    if (token == null) {
      throw Exception('Invalid reset password link');
    }
    return MaterialPageRoute(
      builder: (context) => ResetPasswordScreen(token, latitude, longitude),
    );
  }

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                "Reset Password",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Enter your new password",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 30),
              InputField(
                label: "New Password",
                controller: _passwordController,
                obscureText: true,
              ),
              SizedBox(height: 16),
              InputField(
                label: "Confirm Password",
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Reset Password",
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
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SignUpLoginScreen(
                                  widget.latitude,
                                  widget.longitude,
                                )),
                        (route) => false);

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

  Future<void> _handleResetPassword() async {
    // Validate passwords
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthRepository>().resetPassword(
            token: widget.token,
            password: _passwordController.text,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset successful'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => SignUpLoginScreen(
                  widget.latitude,
                  widget.longitude,
                )),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// Custom InputField widget with controller
class InputField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController controller;

  const InputField({
    Key? key,
    required this.label,
    required this.controller,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
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
