import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/widgets/availability_section.dart';
import 'package:roomify_app/widgets/input_field.dart';
import 'package:roomify_app/widgets/custom_textfield.dart';
import 'package:roomify_app/widgets/property_image_list.dart';
import 'package:roomify_app/widgets/category_chip.dart';
import 'package:roomify_app/widgets/amenity_chip.dart';
import 'package:roomify_app/widgets/map_box_auto_complete_widget.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class EditProfileScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  EditProfileScreen({required this.latitude, required this.longitude});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;
  String? _selectedStatus;
  File? _profileImage;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _universityController;
  late TextEditingController _locationController;
  late TextEditingController _genderController;
  late TextEditingController _statusController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  Listing? _listing;
  List<String> _originalImageUrls = [];
  String? _moveInDate;
  String? _moveOutDate;
  String? _title;
  String? _description;
  List<File> _images = [];
  List<String> _amenities = [];
  String? _address;
  List<String> _customFeatures = [];
  TextEditingController _customFeatureController = TextEditingController();
  String? _phoneNumber;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    // Initialize listing data if provided

    // Initialize user data
    _selectedGender = user?.gender ?? '';
    _selectedStatus = user?.status ?? '';
    _bioController = TextEditingController(text: user?.bio ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _genderController = TextEditingController(text: user?.gender ?? '');
    _statusController = TextEditingController(text: user?.status ?? '');
    _titleController = TextEditingController(text: _listing?.title ?? '');
    _phoneNumber = user?.phoneNumber ?? '34432432';
    _descriptionController =
        TextEditingController(text: _listing?.description ?? '');
    _loadUserPreferences();

    if (user != null) {
      setState(() {
        _nameController.text = user.displayName;
        _emailController.text = user.email;
        _selectedGender = user.gender;
        _selectedStatus = user.status;
        _bioController.text = user.bio ?? '';
        _ageController.text = user.age?.toString() ?? '';
        _universityController.text = user.university ?? '';
        _locationController.text = user.location ?? '';
        _genderController.text = user.gender ?? '';
        _statusController.text = user.status ?? '';
        if (user.isProfessional) {
          _listing = user.listings != null && user.listings.isNotEmpty
              ? user.listings.where((listing) => listing.property != null).first
              : Listing(
                  id: 0,
                  title: '',
                  description: '',
                  location: '',
                  latitude: 0,
                  longitude: 0,
                  price: 0,
                  createdAt: DateTime.now(),
                  type: ListingType.Property,
                  user: user,
                  isFavorite: false,
                  imageUrls: [],
                  property: Property(
                    numberOfBedrooms: 0,
                    numberOfBathrooms: 0,
                    maxOccupancy: 0,
                    moveInDate: DateTime.now().toIso8601String().split('T')[0],
                    moveOutDate: null,
                    walkScore: 0,
                    transitScore: 0,
                    transitDetails: {},
                    lastLocationDetailsUpdate: null,
                    isRoomifyChoice: false,
                    imageUrls: [],
                    categories: [],
                    amenities: [],
                    floorPlans: [],
                    isLookingForRoomate: false,
                  ),
                );
        }
      });
    }

    _originalImageUrls = List<String>.from(_listing?.property?.imageUrls ?? []);
    _titleController = TextEditingController(text: _listing?.title);
    _descriptionController = TextEditingController(text: _listing?.description);
    _moveInDate = _listing?.property?.moveInDate;
    _moveOutDate = _listing?.property?.moveOutDate;
    _amenities = List<String>.from(_listing?.property?.amenities ?? []);
    _address = _listing?.location;

    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _genderController = TextEditingController(text: user?.gender ?? '');
    _statusController = TextEditingController(text: user?.status ?? '');
    _titleController = TextEditingController(text: _listing?.title ?? '');
    _descriptionController =
        TextEditingController(text: _listing?.description ?? '');

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 50.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
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

    // Check which fields are missing
    List<String> missingFields = [];
    if (user.bio == null || user.bio!.isEmpty) missingFields.add('Bio');
    if (user.preferences.isEmpty) missingFields.add('Preferences');
    if (user.profilePhotoUrl == null) missingFields.add('Profile Photo');
    if (user.gender == null) missingFields.add('Gender');
    if (user.status == null) missingFields.add('Status');
    if (user.age == null) missingFields.add('Age');

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
          if (!isComplete && !user.isProfessional) ...[
            SizedBox(height: 12),
            Text(
              'Missing Fields:',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missingFields
                  .map((field) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            SizedBox(width: 4),
                            Text(
                              field,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
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
    final user = context.watch<AuthProvider>().user;
    final isProfessional = user?.isProfessional ?? false;

    return Scaffold(
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: Offset(0, 0.1),
              ).animate(_slideAnimation),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                      key: _formKey,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).padding.top),
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
                                            ? NetworkImage(
                                                user!.profilePhotoUrl!)
                                            : null) as ImageProvider?,
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
                                onPressed: () => context
                                    .read<AuthProvider>()
                                    .deleteProfilePhoto(),
                                child: Text('Remove Photo'),
                              ),
                            if (!isProfessional) ...[
                              _buildProfileCompletion(user),
                            ] else ...[
                              SizedBox(
                                height: 10,
                              ),
                            ],
                            _buildInputFieldWithIndicator(
                              controller: _displayNameController,
                              keyboardType: TextInputType.name,
                              label: isProfessional
                                  ? 'Company Name'
                                  : 'Display Name',
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Name is required';
                                return null;
                              },
                            ),
                            InputField(
                              controller: _emailController,
                              label: "Email",
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Email is required';
                                if (!value!.contains('@'))
                                  return 'Invalid email';
                                return null;
                              },
                            ),
                            if (!isProfessional) ...[
                              InputField(
                                controller: _universityController,
                                label: "University",
                                keyboardType: TextInputType.name,
                              ),
                              SizedBox(height: 16),
                              //PHONE NUMBER
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                initialValue: user?.phoneNumber,
                                initialCountryCode: 'US',
                                onChanged: (phone) {
                                  setState(() {
                                    _phoneNumber = phone.completeNumber;
                                  });
                                },
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
                                children:
                                    availablePreferences.map((preference) {
                                  return FilterChip(
                                    label: Text(preference),
                                    selected: _selectedPreferences
                                        .contains(preference),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedPreferences.add(preference);
                                        } else {
                                          _selectedPreferences
                                              .remove(preference);
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
                            ] else ...[
                              SizedBox(height: 20),
                              Text(
                                'Listing Title',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: blackTextColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                onChanged: (name) {
                                  setState(() {
                                    _listing!.title = name!;
                                  });
                                },
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Enter Property title',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a title'
                                    : null,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Property Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: blackTextColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: _descriptionController,
                                onChanged: (description) {
                                  setState(() {
                                    _listing!.description = description!;
                                  });
                                },
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Enter property details',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter property details'
                                    : null,
                              ),
                              SizedBox(height: 24),
                              _buildPropertyImagesSection(),
                              SizedBox(height: 24),
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: blackTextColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildAddressField(),
                              SizedBox(height: 12),
                              Text(
                                "Amenities",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: blackTextColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _buildAmenityChip('Parking Lot'),
                                      _buildAmenityChip('Pet Allowed'),
                                      _buildAmenityChip('Garden'),
                                      _buildAmenityChip('Gym'),
                                      _buildAmenityChip('Park'),
                                      _buildAmenityChip('Home theatre'),
                                      _buildAmenityChip("Kid's Friendly"),
                                      ..._customFeatures.map((feature) =>
                                          _buildAmenityChip(feature)),
                                      InkWell(
                                        onTap: _showAddFeatureDialog,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add,
                                                  size: 18,
                                                  color: Colors.grey[600]),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add Amenities',
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              AvailabilitySection(
                                moveInDate: _listing!.property!.moveInDate,
                                moveOutDate: _listing!.property!.moveOutDate,
                                onSelectDate: _selectDate,
                                onClearMoveOutDate: (value) {
                                  setState(() {
                                    _listing!.property!.moveOutDate = value;
                                  });
                                },
                              ),
                            ],

                            if (isProfessional) ...[
                              SizedBox(height: 10),
                              _buildEditFloorPlansSection(_listing),
                            ],
                            SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleProfileUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
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
                          ])),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProfileUpdate() async {
    // Start animations
    await _animationController.forward();

    // Update profile
    await context.read<AuthProvider>().updateProfile(
          context: context,
          displayName: _displayNameController.text,
          bio: _bioController.text,
          age: _ageController.text.isNotEmpty
              ? int.tryParse(_ageController.text)
              : null,
          university: _universityController.text,
          location: _locationController.text,
          gender: _selectedGender,
          status: _selectedStatus,
          email: _emailController.text,
          profileImage: _profileImage,
          phoneNumber: _phoneNumber,
        );

    // Reset and play reverse animations
    await _animationController.reverse();

    // Show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildEditFloorPlansSection(Listing? listing) {
    // Check if required fields are filled
    bool canAddFloorPlans = listing!.title != "" && listing.description != "";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Floor Plans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed:
                  canAddFloorPlans ? () => _showFloorPlanDialog(context) : null,
              icon: Icon(Icons.add,
                  color: canAddFloorPlans ? orangeColor : Colors.grey),
              label: Text(
                'Add New',
                style: TextStyle(
                    color: canAddFloorPlans ? orangeColor : Colors.grey),
              ),
            ),
          ],
        ),
        if (listing!.property!.floorPlans!.isEmpty)
          Center(
            child: Text(
              'No floor plans added yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: listing!.property!.floorPlans!.length,
            padding: EdgeInsets.only(top: 10),
            itemBuilder: (context, index) {
              final plan = listing!.property!.floorPlans![index];
              return Container(
                margin: EdgeInsets.only(bottom: 20),
                height: 122,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      child: Hero(
                        tag: 'floor-plan-${plan.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: plan.imageUrl != null
                                  ? NetworkImage(plan.imageUrl!)
                                  : NetworkImage(
                                      'https://images.pexels.com/photos/186077/pexels-photo-186077.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan.bedrooms} bd, ${plan.bathrooms} ba',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${plan.name}',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${plan.squareFeet} sqft',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            '${plan.availableUnits} unit avail. now',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "\$${plan.price.toStringAsFixed(2)}",
                            style: AppTextStyles.small(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: GestureDetector(
                              onTap: () => _showFloorPlanDialog(context, plan),
                              child: Text(
                                "Edit",
                                style: AppTextStyles.small(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        ])
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showFloorPlanDialog(BuildContext context,
      [FloorPlan? plan]) async {
    // Check if listing exists, if not create it first
    if (_listing == null || _listing!.id == 0) {
      try {
        setState(() => _isLoading = true);

        // Create a new listing with basic details
        final newListing =
            await context.read<PropertyProvider>().createProperty(
                  Listing(
                    id: 0,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    location: _locationController.text.trim(),
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    price: 0,
                    createdAt: DateTime.now(),
                    type: ListingType.Property,
                    user: context.read<AuthProvider>().user,
                    isFavorite: false,
                    imageUrls: [],
                    property: Property(
                      numberOfBedrooms: 0,
                      numberOfBathrooms: 0,
                      maxOccupancy: 0,
                      moveInDate: _listing!.property!.moveInDate,
                      moveOutDate: _listing!.property!.moveOutDate,
                      walkScore: 0,
                      transitScore: 0,
                      transitDetails: {},
                      lastLocationDetailsUpdate: null,
                      isRoomifyChoice: false,
                      imageUrls: [],
                      categories: [],
                      amenities: _listing!.property!.amenities,
                      floorPlans: [],
                      isLookingForRoomate: false,
                    ),
                  ),
                  images: _images,
                );

        setState(() {
          _listing = newListing;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create listing: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    Map<String, dynamic> result = await showDialog(
      context: context,
      builder: (context) => FloorPlanDialog(floorPlan: plan),
    );

    final floorPlan = result["floorPlan"] as FloorPlan;
    final imageFile = result["imageFile"] as File?;

    if (floorPlan != null) {
      setState(() => _isLoading = true);
      try {
        Listing updatedListing;

        if (plan == null) {
          // Adding new floor plan
          updatedListing = await context.read<PropertyProvider>().addFloorPlan(
                _listing!,
                floorPlan: floorPlan,
                imageFile: imageFile,
              );
        } else if (floorPlan.id == plan.id) {
          // Updating existing floor plan
          updatedListing =
              await context.read<PropertyProvider>().updateFloorPlan(
                    _listing!.id,
                    plan.id,
                    {
                      'name': floorPlan.name,
                      'bedrooms': floorPlan.bedrooms.toDouble(),
                      'bathrooms': floorPlan.bathrooms.toDouble(),
                      'squareFootage': floorPlan.squareFeet,
                      'price': floorPlan.price,
                      'unitsAvailable': floorPlan.availableUnits.toDouble(),
                    },
                    imageFile: imageFile,
                  );
        } else if (floorPlan.id.isEmpty) {
          // Delete floor plan
          updatedListing =
              await context.read<PropertyProvider>().deleteFloorPlan(
                    _listing!.id,
                    plan.id,
                  );
        } else {
          throw Exception('Invalid floor plan operation');
        }

        setState(() {
          _listing = updatedListing;
        });
        await context.read<ProfileProvider>().updatePreferences(
              preferences: _selectedPreferences,
            );
        await context.read<AuthProvider>().loadUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              plan == null
                  ? 'Floor plan added successfully'
                  : floorPlan.id.isEmpty
                      ? 'Floor plan deleted successfully'
                      : 'Floor plan updated successfully',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${plan == null ? 'add' : floorPlan.id.isEmpty ? 'delete' : 'update'} floor plan: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final isSelected = _listing?.property?.categories.contains(label) ?? false;
    return CategoryChip(
      label: label,
      icon: icon,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          if (_listing?.property != null) {
            if (isSelected) {
              _listing!.property = _listing!.property!.copyWith(
                  categories: List<String>.from(_listing!.property!.categories)
                    ..remove(label));
            } else {
              _listing!.property = _listing!.property!.copyWith(
                  categories: List<String>.from(_listing!.property!.categories)
                    ..add(label));
            }
          }
        });
      },
    );
  }

  Widget _buildAmenityChip(String label) {
    final isSelected = _listing?.property?.amenities.contains(label) ?? false;
    return AmenityChip(
      label: label,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          if (_listing?.property != null) {
            if (isSelected) {
              _listing!.property!.amenities.remove(label);
            } else {
              _listing!.property!.amenities.add(label);
            }
          }
        });
      },
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        MapBoxAutoCompleteWidget(
          hint: "Enter property address",
          defaultLatitude: _listing?.latitude,
          defaultLongitude: _listing?.longitude,
          onSelect: (place) {
            setState(() {
              _locationController.text =
                  '${place.city ?? ''}, ${place.state ?? ''}'.trim();

              _address = place.placeName;
              _listing!.location =
                  '${place.city ?? ''}, ${place.state ?? ''}'.trim();
              _listing!.latitude = place.geometry.coordinates[1];
              _listing!.longitude = place.geometry.coordinates[0];
              // Update location with city and state
            });
          },
          limit: 5,
        ),
      ],
    );
  }

  void _showAddFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Custom Feature',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _customFeatureController,
          decoration: InputDecoration(
            hintText: 'Swimming Pool',
            hintStyle: TextStyle(
                fontSize: 14, color: Colors.grey[600]!.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_customFeatureController.text.isNotEmpty) {
                setState(() {
                  _customFeatures.add(_customFeatureController.text.trim());
                  _customFeatureController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, bool isMovein, bool isAnytime) async {
    if (isMovein && isAnytime) {
      setState(() {
        _moveInDate = 'Anytime';
        if (_listing?.property != null) {
          _listing!.property!.moveInDate = 'Anytime';
        }
      });
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isMovein) {
          _moveInDate = picked.toIso8601String().split('T')[0];
          if (_listing?.property != null) {
            _listing!.property!.moveInDate = _moveInDate!;
          }
        } else {
          _moveOutDate = picked.toIso8601String().split('T')[0];
          if (_listing?.property != null) {
            _listing!.property!.moveOutDate = _moveOutDate;
          }
        }
      });
    }
  }

  Widget _buildPropertyImagesSection() {
    return PropertyImageList(
      selectedImages: _images,
      existingImageUrls: _listing?.property?.imageUrls ?? [],
      onImagesChanged: (newImages) {
        setState(() {
          _images = newImages;
        });
      },
      onExistingImagesChanged: (newUrls) {
        setState(() {
          if (_listing != null && _listing!.property != null) {
            final updatedProperty = Property(
              numberOfBedrooms: _listing!.property!.numberOfBedrooms,
              numberOfBathrooms: _listing!.property!.numberOfBathrooms,
              maxOccupancy: _listing!.property!.maxOccupancy,
              moveInDate: _listing!.property!.moveInDate,
              moveOutDate: _listing!.property!.moveOutDate,
              walkScore: _listing!.property!.walkScore,
              transitScore: _listing!.property!.transitScore,
              transitDetails: _listing!.property!.transitDetails,
              lastLocationDetailsUpdate:
                  _listing!.property!.lastLocationDetailsUpdate,
              isRoomifyChoice: _listing!.property!.isRoomifyChoice,
              imageUrls: newUrls,
              categories: _listing!.property!.categories,
              amenities: _listing!.property!.amenities,
              floorPlans: _listing!.property!.floorPlans,
              isLookingForRoomate: _listing!.property!.isLookingForRoomate,
            );

            _listing = Listing(
              id: _listing!.id,
              title: _listing!.title,
              description: _listing!.description,
              location: _listing!.location,
              price: _listing!.price,
              latitude: _listing!.latitude,
              longitude: _listing!.longitude,
              createdAt: _listing!.createdAt,
              type: _listing!.type,
              user: _listing!.user,
              isFavorite: _listing!.isFavorite,
              imageUrls: newUrls,
              property: updatedProperty,
            );
          }
        });
      },
    );
  }
}

class FloorPlanDialog extends StatefulWidget {
  final FloorPlan? floorPlan;

  const FloorPlanDialog({Key? key, this.floorPlan}) : super(key: key);

  @override
  _FloorPlanDialogState createState() => _FloorPlanDialogState();
}

class _FloorPlanDialogState extends State<FloorPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _priceController;
  late TextEditingController _squareFeetController;
  late TextEditingController _availableUnitsController;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.floorPlan?.name ?? '');
    _bedroomsController = TextEditingController(
        text: widget.floorPlan?.bedrooms.toString() ?? '0');
    _bathroomsController = TextEditingController(
        text: widget.floorPlan?.bathrooms.toString() ?? '0');
    _priceController =
        TextEditingController(text: widget.floorPlan?.price.toString() ?? '0');
    _squareFeetController = TextEditingController(
        text: widget.floorPlan?.squareFeet.toString() ?? '0');
    _availableUnitsController = TextEditingController(
        text: widget.floorPlan?.availableUnits.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _priceController.dispose();
    _squareFeetController.dispose();
    _availableUnitsController.dispose();
    super.dispose();
  }

  Widget _buildFeatureCounter(String label, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: blackTextColor,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    final currentValue = int.tryParse(controller.text) ?? 0;
                    if (currentValue > 0) {
                      controller.text = (currentValue - 1).toString();
                    }
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  controller.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    final currentValue = int.tryParse(controller.text) ?? 0;
                    controller.text = (currentValue + 1).toString();
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Hero(
        tag: widget.floorPlan != null
            ? 'floor-plan-${widget.floorPlan!.id}'
            : 'new-floor-plan',
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : widget.floorPlan?.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                          widget.floorPlan!.imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: _selectedImage == null &&
                                widget.floorPlan?.imageUrl == null
                            ? Center(
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey))
                            : null,
                      ),
                      Positioned(
                        right: 8,
                        top: 0,
                        child: Container(
                          width: 35,
                          padding: EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.2),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.all(0),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                              );
                              if (image != null) {
                                setState(() {
                                  _selectedImage = File(image.path);
                                });
                              }
                            },
                            icon: Icon(Icons.edit_rounded,
                                color: Colors.orange, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Floor Plan Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            CustomTextField(
                              controller: _nameController,
                              hintText: 'Floor Plan Name',
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Square Feet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            CustomTextField(
                              controller: _squareFeetController,
                              hintText: 'Square Feet',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                if (double.tryParse(value!) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            CustomTextField(
                              controller: _priceController,
                              hintText: 'Price',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter a price';
                                }
                                if (double.tryParse(value!) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Units',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            CustomTextField(
                              controller: _availableUnitsController,
                              hintText: 'Available Units',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                if (int.tryParse(value!) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildFeatureCounter('Bedrooms', _bedroomsController),
                  SizedBox(height: 16),
                  _buildFeatureCounter('Bathrooms', _bathroomsController),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      if (widget.floorPlan != null) ...[
                        GestureDetector(
                          onTap: () {
                            // Return a FloorPlan with empty id to indicate deletion
                            Navigator.pop(
                              context,
                              FloorPlan(
                                id: '',
                                name: '',
                                bedrooms: 0,
                                bathrooms: 0,
                                squareFeet: 0,
                                price: 0,
                                availableUnits: 0,
                                imageUrl: '',
                              ),
                            );
                          },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Center(
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Spacer(),
                      ],
                      GestureDetector(
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            final floorPlan = {
                              "imageFile": _selectedImage,
                              "floorPlan": FloorPlan(
                                id: widget.floorPlan?.id ?? '',
                                name: _nameController.text,
                                bedrooms: int.parse(_bedroomsController.text),
                                bathrooms: int.parse(_bathroomsController.text),
                                squareFeet:
                                    double.parse(_squareFeetController.text),
                                price: double.parse(_priceController.text),
                                availableUnits:
                                    int.parse(_availableUnitsController.text),
                                imageUrl: widget.floorPlan?.imageUrl ?? '',
                              )
                            };
                            Navigator.pop(context, floorPlan);
                          }
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Center(
                              child: Text(
                                widget.floorPlan == null
                                    ? 'Add Floor Plan'
                                    : 'Update Floor Plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
