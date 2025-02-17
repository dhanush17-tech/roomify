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
import 'package:roomify_app/widgets/property_image_list.dart';
import 'package:roomify_app/widgets/category_chip.dart';
import 'package:roomify_app/widgets/amenity_chip.dart';
import 'package:roomify_app/widgets/map_box_auto_complete_widget.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl/intl.dart';

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
  TextEditingController _emailController = TextEditingController();
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
  late Animation<double> _scaleAnimation;
  late Animation<double> _formOpacityAnimation;

  List<String> _selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _initializeControllers(user);
    _initializeAnimations();
    _loadUserPreferences();

    if (user != null && user.isProfessional) {
      _initializeProfessionalListing(user);
    }

    // Start entry animation
    _animationController.forward();
  }

  void _initializeControllers(User? user) {
    // Initialize all controllers with user data
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
    _genderController = TextEditingController(text: user?.gender ?? '');
    _statusController = TextEditingController(text: user?.status ?? '');
    _phoneNumber = user?.phoneNumber;

    // Initialize selection values
    _selectedGender = user?.gender;
    _selectedStatus = user?.status;
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _formOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  void _initializeProfessionalListing(User user) {
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

    // Initialize listing-related controllers and data
    _titleController = TextEditingController(text: _listing?.title ?? '');
    _descriptionController =
        TextEditingController(text: _listing?.description ?? '');
    _originalImageUrls = List<String>.from(_listing?.property?.imageUrls ?? []);
    _moveInDate = _listing?.property?.moveInDate;
    _moveOutDate = _listing?.property?.moveOutDate;
    _amenities = List<String>.from(_listing?.property?.amenities ?? []);
    _address = _listing?.location;
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

  void _loadUserPreferences() {
    final user = context.read<AuthProvider>().user;
    if (user != null && !user.isProfessional) {
      setState(() {
        _selectedPreferences =
            user.preferences?.map((p) => p.preference).toList() ?? [];
        print('Loaded preferences: $_selectedPreferences'); // Debug log
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
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                ),
              );
            },
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _formOpacityAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                              value: _selectedGender?.isNotEmpty == true
                                  ? _selectedGender
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              hint: Text('Select Gender'),
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
                              validator: (value) => value == null
                                  ? 'Please select a gender'
                                  : null,
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
                                  selected:
                                      _selectedPreferences.contains(preference),
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
                              value: _selectedStatus?.isNotEmpty == true
                                  ? _selectedStatus
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              hint: Text('Select Status'),
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
                              validator: (value) => value == null
                                  ? 'Please select a status'
                                  : null,
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
                                    ..._listing!.property!.amenities!
                                        .map((amenity) {
                                      if (amenity != 'Parking Lot' &&
                                          amenity != 'Pet Allowed' &&
                                          amenity != 'Garden' &&
                                          amenity != 'Gym' &&
                                          amenity != 'Park' &&
                                          amenity != 'Home theatre' &&
                                          amenity != "Kid's Friendly") {
                                        return _buildAmenityChip(amenity);
                                      }
                                      return Container(
                                        width: 0,
                                        height: 0,
                                      );
                                    }),
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
                            _buildOffersSection(),
                          ],
                          SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleProfileUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: 1 - _fadeAnimation.value,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handleProfileUpdate() async {
    setState(() => _isLoading = true);

    try {
      // Start exit animation
      await _animationController.reverse();

      // Update preferences only for non-professional users
      final user = context.read<AuthProvider>().user;
      if (user!.isProfessional) {
        if (_listing != null) {
          // Calculate deleted image URLs by comparing original URLs with current URLs
          final currentUrls = _listing!.property?.imageUrls ?? [];
          final deletedUrls = _originalImageUrls
              .where((url) => !currentUrls.contains(url))
              .toList();
          print(deletedUrls);
          final updatedListing =
              await context.read<PropertyProvider>().updateProperty(
                    _listing!,
                    newImages: _images,
                    deletedImageUrls: deletedUrls,
                  );
          setState(() {
            _listing = updatedListing;
            _images = []; // Clear new images after successful update
          });
        }
      }
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
      await context.read<ProfileProvider>().updatePreferences(
            preferences: _selectedPreferences,
          );
      // Add success animation
      await Future.delayed(Duration(milliseconds: 300));

      // Refresh user profile to get updated data
      await context.read<AuthProvider>().loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          animation: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // Reset animation on error
      await _animationController.forward();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
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
              _locationController.text = place.placeName.trim();

              _address = place.placeName;
              _listing!.location = place.placeName.trim();
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
              offers: _listing!.property!.offers,
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

  Widget _buildOffersSection() {
    if (!context.read<AuthProvider>().user!.isProfessional) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Special Offers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: blackTextColor,
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.add, color: orangeColor),
              onPressed: _showAddOfferDialog,
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_listing?.property?.offers.isEmpty ?? true)
          Center(
            child: Text(
              'No offers added yet',
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
            itemCount: _listing!.property!.offers.length,
            itemBuilder: (context, index) {
              final offer = _listing!.property!.offers[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            offer.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Valid until: ${DateFormat('MMM d, y').format(offer.validUntil)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteOffer(offer.id),
                    ),
                  ],
                ),
              );
            },
          ),
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showAddOfferDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Special Offer",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Offer Title",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an offer title';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Offer Description",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an offer description';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedDate == null
                                    ? Colors.red
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.grey[600]),
                                SizedBox(width: 12),
                                Text(
                                  selectedDate == null
                                      ? "Select Valid Until Date"
                                      : "Valid Until: ${DateFormat('MMM d, y').format(selectedDate!)}",
                                  style: TextStyle(
                                    color: selectedDate == null
                                        ? Colors.grey[600]
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (selectedDate == null)
                          Padding(
                            padding: EdgeInsets.only(left: 16, top: 8),
                            child: Text(
                              'Please select a valid until date',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Cancel"),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate() &&
                                selectedDate != null) {
                              _addOffer(
                                title: titleController.text,
                                description: descriptionController.text,
                                validUntil: selectedDate!,
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeColor,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Add Offer",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

  Future<void> _addOffer({
    required String title,
    required String description,
    required DateTime validUntil,
  }) async {
    try {
      setState(() => _isLoading = true);

      // Add the offer through your API
      final response = await context.read<PropertyProvider>().addOffer(
            listingId: _listing!.id,
            title: title,
            description: description,
            validUntil: validUntil,
          );

      setState(() {
        if (_listing?.property != null) {
          _listing!.property = _listing!.property!.copyWith(
            offers: [..._listing!.property!.offers, response],
          );
        }
      });
      print(_listing!.property!.offers);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add offer: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOffer(String offerId) async {
    try {
      setState(() => _isLoading = true);

      await context.read<PropertyProvider>().deleteOffer(
            listingId: _listing!.id,
            offerId: offerId,
          );

      setState(() {
        if (_listing?.property != null) {
          _listing!.property = _listing!.property!.copyWith(
            offers: _listing!.property!.offers
                .where((o) => o.id != offerId)
                .toList(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Offer deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete offer: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _universityController.dispose();

    super.dispose();
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
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _squareFeetController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '0');
  final _bathroomsController = TextEditingController(text: '0');
  final _availableUnitsController = TextEditingController(text: '0');
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.floorPlan != null) {
      _nameController.text = widget.floorPlan!.name;
      _priceController.text = widget.floorPlan!.price.toString();
      _squareFeetController.text = widget.floorPlan!.squareFeet.toString();
      _bedroomsController.text = widget.floorPlan!.bedrooms.toString();
      _bathroomsController.text = widget.floorPlan!.bathrooms.toString();
      _availableUnitsController.text =
          widget.floorPlan!.availableUnits.toString();

      _availableUnitsController.text =
          widget.floorPlan!.availableUnits.toString();
    }
  }

  Widget _buildFeatureCounter(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () {
                  final value = int.tryParse(controller.text) ?? 0;
                  if (value > 0) {
                    controller.text = (value - 1).toString();
                  }
                },
              ),
              Container(
                width: 40,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () {
                  final value = int.tryParse(controller.text) ?? 0;
                  controller.text = (value + 1).toString();
                },
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
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.floorPlan == null
                      ? "Add Floor Plan"
                      : "Edit Floor Plan",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          imageQuality: 70,
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          setState(() {
                            _selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
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
                          border: Border.all(
                            color: (_selectedImage == null &&
                                    widget.floorPlan?.imageUrl == null)
                                ? Colors.red
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImage == null &&
                        widget.floorPlan?.imageUrl == null)
                      Positioned(
                        bottom: 8,
                        left: 16,
                        child: Text(
                          'Please select an image',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Floor Plan Name",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a floor plan name';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Price",
                            prefixText: "\$ ",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextFormField(
                          controller: _squareFeetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Square Feet",
                            suffixText: "sq ft",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid value';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildFeatureCounter("Bedrooms", _bedroomsController),
                SizedBox(height: 16),
                _buildFeatureCounter("Bathrooms", _bathroomsController),
                SizedBox(height: 16),
                _buildFeatureCounter(
                    "Available Units", _availableUnitsController),
                SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.floorPlan != null)
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pop(context, {"delete": true}),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (widget.floorPlan != null) SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              (_selectedImage != null ||
                                  widget.floorPlan?.imageUrl != null)) {
                            // Validate bedrooms and bathrooms
                            final bedrooms =
                                int.tryParse(_bedroomsController.text);
                            final bathrooms =
                                int.tryParse(_bathroomsController.text);

                            if (bedrooms == null ||
                                bedrooms < 0 ||
                                bathrooms == null ||
                                bathrooms < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Please enter valid numbers for bedrooms and bathrooms'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context, {
                              "imageFile": _selectedImage,
                              "floorPlan": FloorPlan(
                                id: widget.floorPlan?.id ?? '',
                                name: _nameController.text,
                                imageUrl: widget.floorPlan?.imageUrl ?? '',
                                bedrooms: bedrooms,
                                bathrooms: bathrooms,
                                price: double.parse(_priceController.text),
                                squareFeet:
                                    double.parse(_squareFeetController.text),
                                availableUnits:
                                    int.parse(_availableUnitsController.text),
                              ),
                            });
                          } else if (_selectedImage == null &&
                              widget.floorPlan?.imageUrl == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Please select a floor plan image'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.floorPlan == null
                              ? "Add Floor Plan"
                              : "Update",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );
  }
}
