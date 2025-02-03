import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/repository/profile_repo.dart';
import 'package:roomify_app/repository/properties_repo.dart';
import 'package:roomify_app/repository/marketplace_repo.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/auth/forgot_passoword.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:roomify_app/widgets/map_box_auto_complete_widget.dart';

import '../onboarding/main_onboarding.dart';

class SignUpLoginScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  SignUpLoginScreen(this.latitude, this.longitude);
  @override
  _SignUpLoginScreenState createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collegeController = TextEditingController();
  final _locationController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLogin = true;
  bool _isProfessionalUser = false;
  bool _rememberMe = true;
  final _formKey = GlobalKey<FormState>();
  String _phoneNumber = '';
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _collegeController.dispose();
    _locationController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _ageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-initialize providers if needed
    Provider.of<AuthProvider>(context, listen: false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PropertyRepository>(
          create: (_) => PropertyRepository(),
        ),
        Provider<ProfileUpdateRepo>(
          create: (_) => ProfileUpdateRepo(),
        ),
        Provider<MarketplaceRepository>(
          create: (_) => MarketplaceRepository(),
        ),
        ChangeNotifierProxyProvider<PropertyRepository, PropertyProvider>(
          create: (context) => PropertyProvider(
            context.read<PropertyRepository>(),
            context,
          ),
          update: (context, repo, previous) =>
              previous ?? PropertyProvider(repo, context),
        ),
        ChangeNotifierProxyProvider<ProfileUpdateRepo, ProfileProvider>(
          create: (context) => ProfileProvider(
            context.read<ProfileUpdateRepo>(),
            context,
          ),
          update: (context, repo, previous) =>
              previous ?? ProfileProvider(repo, context),
        ),
        ChangeNotifierProxyProvider<MarketplaceRepository, MarketplaceProvider>(
          create: (context) => MarketplaceProvider(
            context.read<MarketplaceRepository>(),
            context,
          ),
          update: (context, repo, previous) =>
              previous ?? MarketplaceProvider(repo, context),
        ),
      ],
      child: MainScreen(
        latitude: widget.latitude,
        longitude: widget.longitude,
      ),
    );
  }

  void _handleSuccessfulAuth(BuildContext context) {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => _buildMainScreen(context),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authViewModel, child) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      Text(
                        "Get Started now",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Make your next moveout faster with Roomify",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: orangeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerHeight: 0,
                          labelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          tabs: [
                            Tab(text: 'Log In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (authViewModel.error != null)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authViewModel.error!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Login Tab
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: _emailController,
                                hintText: "Email",
                                icon: Icons.email_outlined,
                              ),
                              SizedBox(height: 16),
                              _buildInputField(
                                controller: _passwordController,
                                hintText: "Password",
                                icon: Icons.lock_outline,
                                obscureText: true,
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value!;
                                            });
                                          },
                                          activeColor: orangeColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Remember me",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (c) =>
                                              ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: orangeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : () {
                                          if (_emailController.text.isEmpty ||
                                              _passwordController
                                                  .text.isEmpty) {
                                            _showErrorDialog(
                                                'Please fill in all fields');
                                            return;
                                          }

                                          authViewModel.login(
                                            context,
                                            _emailController.text,
                                            _passwordController.text,
                                            () =>
                                                _handleSuccessfulAuth(context),
                                            rememberMe: _rememberMe,
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authViewModel.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          "Log In",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(color: Colors.grey[300])),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      "Don't have an account?",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(color: Colors.grey[300])),
                                ],
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _tabController
                                        .animateTo(1); // Switch to signup tab
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Create an account",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Sign Up Tab
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                controller: _nameController,
                                hintText: "Full Name",
                                icon: Icons.person_outline,
                              ),
                              SizedBox(height: 16),
                              _buildInputField(
                                controller: _emailController,
                                hintText: "Email",
                                icon: Icons.email_outlined,
                              ),
                              SizedBox(height: 16),
                              _buildInputField(
                                controller: _passwordController,
                                hintText: "Password",
                                icon: Icons.lock_outline,
                                obscureText: true,
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "I am a:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    RadioListTile<bool>(
                                      title:
                                          Text("Student looking for housing"),
                                      value: false,
                                      groupValue: _isProfessionalUser,
                                      onChanged: (value) {
                                        setState(() {
                                          _isProfessionalUser = value!;
                                        });
                                      },
                                      activeColor: orangeColor,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    RadioListTile<bool>(
                                      title: Text("Property manager/company"),
                                      value: true,
                                      groupValue: _isProfessionalUser,
                                      onChanged: (value) {
                                        setState(() {
                                          _isProfessionalUser = value!;
                                        });
                                      },
                                      activeColor: orangeColor,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isProfessionalUser) ...[
                                SizedBox(height: 16),
                                _buildInputField(
                                  controller: _ageController,
                                  hintText: "Age",
                                  icon: Icons.cake_outlined,
                                ),
                                SizedBox(height: 16),
                                _buildInputField(
                                  controller: _collegeController,
                                  hintText: "University/College",
                                  icon: Icons.school_outlined,
                                ),
                                SizedBox(height: 16),
                                Container(
                  
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
                                  child: MapBoxAutoCompleteWidget(
                                    hint: "Enter your location",
                                    inputDecoration: InputDecoration(
                                      hintText: "Enter your location",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[500]),
                                      prefixIcon: Icon(Icons.location_on_outlined,
                                          color: Colors.grey[600], size: 22),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 16),
                                    ),
                                    onSelect: (Place place) {
                                      setState(() {
                                        _locationController.text =
                                            place.placeName;
                                        _latitude = place.geometry.coordinates[1];
                                        _longitude =
                                            place.geometry.coordinates[0];
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                                IntlPhoneField(
                                  pickerDialogStyle: PickerDialogStyle(
                                    padding: EdgeInsets.all(16),
                                    searchFieldInputDecoration: InputDecoration(
                                      hintText: 'Search for a country',
                                      prefixIcon: Icon(
                                        Icons.search_outlined,
                                        color: Colors.grey[600],
                                      ),
                                      hintStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: 'Phone Number',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                  ),
                                  initialCountryCode: 'US',
                                  onChanged: (phone) {
                                    setState(() {
                                      _phoneNumber = phone.completeNumber;
                                    });
                                  },
                                ),
                              ],
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : () {
                                          if (!_isProfessionalUser &&
                                              (_ageController.text.isEmpty ||
                                                  _collegeController
                                                      .text.isEmpty ||
                                                  _locationController
                                                      .text.isEmpty)) {
                                            _showErrorDialog(
                                                'Please fill in all required fields');
                                            return;
                                          }

                                          authViewModel.register(
                                            context: context,
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                            displayName: _nameController.text,
                                            phoneNumber: _phoneNumber,
                                            university: _isProfessionalUser
                                                ? null
                                                : _collegeController.text,
                                            location: _isProfessionalUser
                                                ? null
                                                : _locationController.text,
                                            latitude: _isProfessionalUser
                                                ? null
                                                : _latitude,
                                            longitude: _isProfessionalUser
                                                ? null
                                                : _longitude,
                                            age: _isProfessionalUser
                                                ? null
                                                : int.tryParse(
                                                    _ageController.text),
                                            isProfessional: _isProfessionalUser,
                                            onSuccess: () =>
                                                _handleSuccessfulAuth(context),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authViewModel.isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          "Create Account",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String icon,
    required String text,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: backgroundColor == Colors.white
                ? BorderSide(color: Colors.grey[300]!)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: 24,
              width: 24,
            ),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
