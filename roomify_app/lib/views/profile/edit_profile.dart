import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _universityController.text = user.university ?? '';
      _bioController.text = user.bio ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _selectedGender = user.gender;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Consumer<UserProvider>(
        builder: (context, UserProvider, child) {
          final user = UserProvider.user;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
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
                  SizedBox(height: 20),
                  if (user?.profilePhotoUrl != null)
                    TextButton(
                      onPressed: () => UserProvider.deleteProfilePhoto(),
                      child: Text('Remove Photo'),
                    ),
                  InputField(
                    controller: _nameController,
                    label: "Full Name",
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Name is required';
                      return null;
                    },
                  ),
                  InputField(
                    controller: _emailController,
                    label: "Email",
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
                  if (UserProvider.isLoading)
                    CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: () => _updateProfile(UserProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Save Changes'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateProfile(UserProvider UserProvider) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await UserProvider.updateProfile(
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
