import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/auth/login.dart';
import 'package:roomify_app/widgets/map_box_auto_complete_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phone_number_hint/phone_number_hint.dart';

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
  bool _isPhoneLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _collegeController = TextEditingController();
  final _locationController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isProfessionalUser = false;

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
                _latitude = position.latitude;
                _longitude = position.longitude;
              });
            }
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
    setState(() => _isPhoneLoading = true);
    try {
      final phoneHint = PhoneNumberHint();
      final phoneNumber = await phoneHint.requestHint();
      if (phoneNumber != null && mounted) {
        // Extract country code and national number
        String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        setState(() {
          _phoneNumber = formattedNumber;
          _isPhoneLoading = false;
        });
      }
    } catch (e) {
      print('Error getting phone number: $e');
    } finally {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: getInputDecoration(
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      title: Text("Student looking for housing"),
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            size: 22,
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
                            child: Center(
                              child: CircularProgressIndicator(),
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
                      initialValue:
                          _phoneNumber.replaceAll(RegExp(r'^\+\d{1,2}'), ''),
                      controller: TextEditingController(
                          text: _phoneNumber.replaceAll(
                              RegExp(r'^\+\d{1,2}'), '')),
                      pickerDialogStyle: PickerDialogStyle(
                        padding: EdgeInsets.all(16),
                        searchFieldInputDecoration: InputDecoration(
                          hintText: 'Search for a country',
                          prefixIcon: Icon(Icons.search_outlined,
                              color: Colors.grey[600]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: _isPhoneLoading
                            ? 'Loading phone number...'
                            : 'Phone Number',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                          color: Colors.white.withOpacity(0.7),
                          child: Center(
                            child: CircularProgressIndicator(),
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
                  onPressed: widget.authViewModel.isLoading
                      ? null
                      : () {
                          if (!_signupFormKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Please fill all required fields')),
                            );
                            return;
                          }

                          if (!_isProfessionalUser &&
                              (_phoneNumber.isEmpty ||
                                  _locationController.text.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Phone number and location are required')),
                            );
                            return;
                          }

                          widget.authViewModel.register(
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
                            latitude: _isProfessionalUser ? null : _latitude,
                            longitude: _isProfessionalUser ? null : _longitude,
                            age: _isProfessionalUser
                                ? null
                                : int.tryParse(_ageController.text),
                            isProfessional: _isProfessionalUser,
                            onSuccess: () => widget.onSuccess(context),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: widget.authViewModel.isLoading
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
    );
  }
}
