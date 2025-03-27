import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/widgets/map_box_auto_complete_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:roomify_app/utils/location_manager.dart';

class Register extends StatefulWidget {
  final AuthProvider authViewModel;
  final Function(BuildContext context) onSuccess;
  const Register(
      {super.key, required this.authViewModel, required this.onSuccess});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String _phoneNumber = '';
  double? _latitude;
  double? _longitude;
  final _signupFormKey = GlobalKey<FormState>();
  bool _isLocationLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collegeController = TextEditingController();
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isProfessionalUser = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _collegeController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final position = await LocationManager().getCurrentPosition();

      setState(() {
        _locationController.text = "Loading address...";
      });

      final response = await http.get(Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${position.longitude},${position.latitude}.json?access_token=${mapboxToken}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          setState(() {
            _locationController.text = data['features'][0]['place_name'];
            _latitude = position.latitude;
            _longitude = position.longitude;
          });
        }
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

  void _showManagerSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Request Submitted',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Your manager account request has been submitted for review.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'You will receive your login credentials via email once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Close the registration screen
              },
              child: Text('OK', style: TextStyle(color: orangeColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_signupFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_isProfessionalUser &&
        (_phoneNumber.isEmpty || _locationController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number and location are required')),
      );
      return;
    }

    try {
      final success = await widget.authViewModel.register(
        context: context,
        email: _emailController.text,
        password: _isProfessionalUser ? '' : _passwordController.text,
        displayName: _nameController.text,
        phoneNumber: _phoneNumber,
        university: _isProfessionalUser ? null : _collegeController.text,
        location: _isProfessionalUser ? null : _locationController.text,
        latitude: _isProfessionalUser ? null : _latitude,
        longitude: _isProfessionalUser ? null : _longitude,
        age: _isProfessionalUser ? null : int.tryParse(_ageController.text),
        isProfessional: _isProfessionalUser,
        onSuccess: () {
          if (_isProfessionalUser) {
            _showManagerSuccessDialog();
          } else {
            widget.onSuccess(context);
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _signupFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isProfessionalUser
                      ? 'Manager Registration'
                      : 'Student Registration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: getInputDecoration(
                    hintText: "Full Name",
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: getInputDecoration(
                    hintText: "Email",
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                // Password fields only for students
                if (!_isProfessionalUser) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: getInputDecoration(
                      hintText: "Password",
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: getInputDecoration(
                      hintText: "Confirm Password",
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword =
                              !_obscureConfirmPassword);
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

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
                        ),
                      ),
                      RadioListTile<bool>(
                        title: Text("Student looking for housing"),
                        value: false,
                        groupValue: _isProfessionalUser,
                        onChanged: (value) =>
                            setState(() => _isProfessionalUser = value!),
                        activeColor: orangeColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        title: Text("Property manager/company"),
                        value: true,
                        groupValue: _isProfessionalUser,
                        onChanged: (value) =>
                            setState(() => _isProfessionalUser = value!),
                        activeColor: orangeColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                // Student-specific fields
                if (!_isProfessionalUser) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: getInputDecoration(
                      hintText: "Age",
                      icon: Icons.cake_outlined,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Age is required';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 18 || age > 100) {
                        return 'Please enter a valid age between 18 and 100';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _collegeController,
                    decoration: getInputDecoration(
                      hintText: "University/College",
                      icon: Icons.school_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'University/College is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
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
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(
                              _isLocationLoading
                                  ? Icons.location_searching
                                  : Icons.location_on_outlined,
                              color: Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          defaultLatitude: _latitude,
                          defaultLongitude: _longitude,
                          onSelect: (Place place) {
                            setState(() {
                              _locationController.text = place.placeName;
                              _latitude = place.geometry.coordinates[1];
                              _longitude = place.geometry.coordinates[0];
                            });
                          },
                        ),
                        if (_isLocationLoading)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white.withOpacity(0.7),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    initialCountryCode: 'US',
                    onChanged: (phone) => _phoneNumber = phone.completeNumber,
                  ),
                ],

                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        widget.authViewModel.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.authViewModel.isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
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
                SizedBox(height: 16),
                if (_isProfessionalUser)
                  Text(
                    'Note: Your account will need to be approved before you can access all features. Login credentials will be emailed to you after approval.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration getInputDecoration(
      {required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
