import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/widgets/input_field.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedStatus;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _universityController.text = user.university ?? '';
      _bioController.text = user.bio ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _selectedGender = user.gender;
      _selectedStatus = user.status;
    }
    _loadUserPreferences();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Widget _buildInputFieldWithIndicator({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
    int? maxLines,
    TextInputType? keyboardType,
  }) {
    bool isEmpty = controller.text.isEmpty;

    return Stack(
      children: [
        InputField(
          controller: controller,
          label: label,
          validator: validator,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
        ),
        if (isEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileCompletion(User? user) {
    if (user == null) return SizedBox();

    double completion = user.getProfileCompletion();
    bool isComplete = user.isProfileComplete();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (!isComplete)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${completion.toStringAsFixed(0)}% Complete',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (!isComplete) ...[
            SizedBox(height: 8),
            Text(
              'Complete your profile to start matching with potential roommates',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const List<String> availablePreferences = [
    'Early riser',
    'Night owl',
    'Non-smoker',
    'Pet lover',
    'Vegetarian',
    'Vegan',
    'Quiet',
    'Social',
    'Tidy',
    'Student',
    'Prefer a Male',
    'Prefer a Female',
  ];
  List<String> _selectedPreferences = [];
  void _loadUserPreferences() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      setState(() {
        _selectedPreferences =
            user.preferences.map((p) => p.preference).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, UserProvider, child) {
          final user = UserProvider.user;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Edit Profile",
                        style: TextStyle(
                          color: blackTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.all(10),
                          backgroundColor: Colors.grey[200],
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Profile Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : (user?.profilePhotoUrl != null
                                  ? NetworkImage(user!.profilePhotoUrl!)
                                  : null),
                          child: user?.profilePhotoUrl == null &&
                                  _profileImage == null
                              ? Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: orangeColor,
                            radius: 18,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user?.profilePhotoUrl != null)
                    TextButton(
                      onPressed: () => UserProvider.deleteProfilePhoto(),
                      child: Text('Remove Photo'),
                    ),
                  _buildProfileCompletion(user),
                  _buildInputFieldWithIndicator(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    label: "Full Name",
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Name is required';
                      return null;
                    },
                  ),
                  InputField(
                    controller: _emailController,
                    label: "Email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Email is required';
                      if (!value!.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  InputField(
                    controller: _passwordController,
                    label: "New Password",
                    obscureText: true,
                  ),
                  InputField(
                    controller: _universityController,
                    label: "University",
                    keyboardType: TextInputType.name,
                  ),
                  InputField(
                    controller: _bioController,
                    label: "Bio",
                    maxLines: 3,
                  ),
                  InputField(
                    controller: _ageController,
                    label: "Age",
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availablePreferences.map((preference) {
                      return FilterChip(
                        label: Text(preference),
                        selected: _selectedPreferences.contains(preference),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPreferences.add(preference);
                            } else {
                              _selectedPreferences.remove(preference);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    items: [
                      "I'm looking for a room",
                      "I'm looking for a roommate",
                      "I'm looking for a roommate and a room"
                    ]
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                  ),
                  SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: UserProvider.isLoading
                          ? null
                          : () => _updateProfile(UserProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: UserProvider.isLoading
                          ? CircularProgressIndicator()
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateProfile(AuthProvider UserProvider) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await UserProvider.updateProfile(
        context: context,
        status: _selectedStatus,
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        university: _universityController.text,
        bio: _bioController.text,
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        profileImage: _profileImage,
      );
      await context.read<ProfileProvider>().updatePreferences(
            preferences: _selectedPreferences,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
