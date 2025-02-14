import 'package:flutter/material.dart';
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
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
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
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
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
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  @override

  /// Builds the sign up form with the following fields:
  ///
  /// * Full name
  /// * Email
  /// * Password
  /// * I am a [Student looking for housing / Property manager/company]
  /// * If student: Age, University/College, Location, Phone number
  /// * If property manager/company: None
  ///
  /// The form is validated and if all fields are valid, it calls the [register]
  /// function of the [AuthViewModel] with the provided fields and [onSuccess]
  /// callback.
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
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
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
                autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
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
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
