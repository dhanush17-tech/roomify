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
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/auth/forgot_passoword.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:roomify_app/widgets/map_box_auto_complete_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:phone_number_hint/phone_number_hint.dart';

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
  final _signupFormKey = GlobalKey<FormState>();
  bool _isLocationLoading = false;
  bool _isPhoneLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _getPhoneNumber();
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
                          child: Form(
                            key: _signupFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _getInputDecoration(
                                    hintText: "Full Name",
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Full name is required';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: _getInputDecoration(
                                    hintText: "Email",
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: _getInputDecoration(
                                    hintText: "Password",
                                    icon: Icons.lock_outline,
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  TextFormField(
                                    controller: _ageController,
                                    decoration: _getInputDecoration(
                                      hintText: "Age",
                                      icon: Icons.cake_outlined,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Age is required';
                                      }
                                      final age = int.tryParse(value);
                                      if (age == null ||
                                          age < 18 ||
                                          age > 100) {
                                        return 'Please enter a valid age between 18 and 100';
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                  SizedBox(height: 16),
                                  TextFormField(
                                    controller: _collegeController,
                                    decoration: _getInputDecoration(
                                      hintText: "University/College",
                                      icon: Icons.school_outlined,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'University/College is required';
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Stack(
                                      children: [
                                        MapBoxAutoCompleteWidget(
                                          hint: _isLocationLoading
                                              ? "Loading location..."
                                              : "Enter your location",
                                          inputDecoration: InputDecoration(
                                            hintText: _isLocationLoading
                                                ? "Loading location..."
                                                : "Enter your location",
                                            hintStyle: TextStyle(
                                                color: Colors.grey[500]),
                                            prefixIcon: Icon(
                                              _isLocationLoading
                                                  ? Icons.location_searching
                                                  : Icons.location_on_outlined,
                                              color: Colors.grey[600],
                                              size: 22,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 16),
                                          ),
                                          onSelect: (Place place) {
                                            setState(() {
                                              _locationController.text =
                                                  place.placeName;
                                              _latitude =
                                                  place.geometry.coordinates[1];
                                              _longitude =
                                                  place.geometry.coordinates[0];
                                            });
                                          },
                                        ),
                                        if (_isLocationLoading)
                                          Positioned.fill(
                                            child: Container(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Stack(
                                    children: [
                                      IntlPhoneField(
                                        enabled: !_isPhoneLoading,
                                        initialValue: _phoneNumber,
                                        pickerDialogStyle: PickerDialogStyle(
                                          padding: EdgeInsets.all(16),
                                          searchFieldInputDecoration:
                                              InputDecoration(
                                            hintText: 'Search for a country',
                                            prefixIcon: Icon(
                                                Icons.search_outlined,
                                                color: Colors.grey[600]),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30)),
                                          ),
                                        ),
                                        decoration: InputDecoration(
                                          labelText: _isPhoneLoading
                                              ? 'Loading phone number...'
                                              : 'Phone Number',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        initialCountryCode: 'US',
                                        onChanged: (phone) {
                                          setState(() {
                                            _phoneNumber = phone.completeNumber;
                                          });
                                        },
                                      ),
                                      if (_isPhoneLoading)
                                        Positioned.fill(
                                          child: Container(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ),
                                    ],
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
                                            if (!_signupFormKey.currentState!
                                                .validate()) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Please fill all required fields')),
                                              );
                                              return;
                                            }

                                            if (!_isProfessionalUser &&
                                                (_phoneNumber.isEmpty ||
                                                    _locationController
                                                        .text.isEmpty)) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Phone number and location are required')),
                                              );
                                              return;
                                            }

                                            authViewModel.register(
                                              context: context,
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
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
                                              isProfessional:
                                                  _isProfessionalUser,
                                              onSuccess: () =>
                                                  _handleSuccessfulAuth(
                                                      context),
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable location services')),
        );
        setState(() => _isLocationLoading = false);
        return;
      }

      // Request permissions one by one
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.phone,
      ].request();

      // Check if location permission is granted
      if (statuses[Permission.location] == PermissionStatus.granted) {
        // Get current position with high accuracy
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        );

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationController.text = "Loading address...";
        });

        // Reverse geocoding using Mapbox
        try {
          final response = await http.get(Uri.parse(
              'https://api.mapbox.com/geocoding/v5/mapbox.places/${position.longitude},${position.latitude}.json?access_token=${mapboxToken}'));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['features'] != null && data['features'].isNotEmpty) {
              setState(() {
                _locationController.text = data['features'][0]['place_name'];
              });
            }
          } else {
            setState(() {
              _locationController.text =
                  '${position.latitude}, ${position.longitude}';
            });
          }
        } catch (e) {
          print("Error in reverse geocoding: $e");
          setState(() {
            _locationController.text =
                '${position.latitude}, ${position.longitude}';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
      }

      // Handle phone permission separately
      if (statuses[Permission.phone] == PermissionStatus.granted) {
        // Phone permission granted, you can handle phone-related functionality here
        await _getPhoneNumber();
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _getPhoneNumber() async {
    try {
      final phoneHint = PhoneNumberHint();
      final phoneNumber = await phoneHint.requestHint();
      if (phoneNumber != null) {
        setState(() {
          _phoneNumber = phoneNumber;
        });
      }
    } catch (e) {
      print('Error getting phone number: $e');
    }
  }

  InputDecoration _getInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Icon(icon, color: Colors.grey[600], size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: orangeColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
