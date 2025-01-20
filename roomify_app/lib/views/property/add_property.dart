import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/widgets/mapbox_widget.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

class AddPropertyScreen extends StatefulWidget {
  final Listing? existingListing;

  AddPropertyScreen({this.existingListing});

  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bathroomsController = TextEditingController(text: '0');
  final _bedroomsController = TextEditingController(text: '0');
  final _maxOccController = TextEditingController(text: '0');
  final List<String> _selectedAmenities = [];
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  bool _isLoading = false;
  PropertyCategory? _selectedCategory;
  bool isLookingForRoomate = false;
  final _addressController = TextEditingController();
  double? latitude;
  double? longitude;
  DateTime? _moveInDate;
  DateTime? _moveOutDate;
  String? moveInDate;
  String? moveOutDate;
  final _customFeatureController = TextEditingController();
  final List<String> _customFeatures = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Map<int, bool> _removingImages = {};
  final Map<int, bool> _addingImages = {};

  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingListing != null) {
      _titleController.text = widget.existingListing!.title;
      _descriptionController.text = widget.existingListing!.description ?? '';
      _locationController.text = widget.existingListing!.location;
      _priceController.text = widget.existingListing!.price.toString();
      _bathroomsController.text =
          widget.existingListing!.property!.numberOfBathrooms.toString();
      _bedroomsController.text =
          widget.existingListing!.property!.numberOfBedrooms.toString();
      _maxOccController.text =
          widget.existingListing!.property!.maxOccupancy.toString();
      _selectedAmenities
          .addAll(widget.existingListing!.property!.amenities ?? []);
      latitude = widget.existingListing!.latitude;
      if (widget.existingListing!.property?.categories != null &&
          widget.existingListing!.property!.categories.isNotEmpty) {
        _selectedCategory = widget.existingListing!.property!.categories.first;
      }
      longitude = widget.existingListing!.longitude;
      moveInDate = widget.existingListing!.property!.moveInDate;
      moveOutDate = widget.existingListing!.property!.moveOutDate;
      if (widget.existingListing!.property!.imageUrls != null) {
        _existingImageUrls.addAll(widget.existingListing!.property!.imageUrls!);
      }
    }
  }

  Future<void> _downloadAndStoreExistingImages() async {
    try {
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < _existingImageUrls.length; i++) {
        final url = _existingImageUrls[i];
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final imagePath = '${tempDir.path}/existing_image_$i.jpg';
          await File(imagePath).writeAsBytes(response.bodyBytes);
          setState(() {
            _selectedImages.add(File(imagePath));
          });
        }
      }
    } catch (e) {
      print('Error downloading existing images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load existing images: $e')),
      );
    }
  }

  @override
  void dispose() {
    // Dispose all TextEditingControllers
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _bathroomsController.dispose();
    _bedroomsController.dispose();
    _maxOccController.dispose();
    _addressController.dispose();
    _customFeatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70, // Compress images for better performance
      );

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _selectedImages.add(File(image.path));
            _addingImages[_selectedImages.length - 1] = true;
          }
        });

        await Future.delayed(Duration(milliseconds: 50));

        for (var i = _selectedImages.length - images.length;
            i < _selectedImages.length;
            i++) {
          setState(() {
            _addingImages.remove(i);
          });
          await Future.delayed(Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  Future<void> _handleSubmit(User user) async {
    if (!_formKey.currentState!.validate()) return;

    // Validation checks
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      _showErrorSnackBar('Please add at least one image');
      return;
    }
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }
    if (latitude == null || longitude == null) {
      _showErrorSnackBar('Please select a valid address');
      return;
    }
    if (_selectedAmenities.isEmpty) {
      _showErrorSnackBar('Please select at least one amenity');
      return;
    }
    if (moveInDate == null) {
      _showErrorSnackBar('Please select a move-in date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<File> allImages = [];
      allImages.addAll(_selectedImages);

      // Convert existing image URLs to files
      for (String imageUrl in _existingImageUrls) {
        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final fileName = imageUrl.split('/').last;
            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(response.bodyBytes);
            allImages.add(tempFile);
          }
        } catch (e) {
          print('Error downloading existing image: $e');
        }
      }

      final listing = Listing(
        id: widget.existingListing?.id ?? DateTime.now().millisecondsSinceEpoch,
        createdAt: widget.existingListing?.createdAt ?? DateTime.now(),
        title: capitalizeWords(_titleController.text.trim()),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        price: int.parse(_priceController.text),
        property: Property(
          numberOfBathrooms: int.parse(_bathroomsController.text),
          numberOfBedrooms: int.parse(_bedroomsController.text),
          amenities: _selectedAmenities,
          isLookingForRoomate: isLookingForRoomate,
          maxOccupancy: int.parse(_maxOccController.text),
          moveInDate: moveInDate,
          moveOutDate: moveOutDate,
          categories: _selectedCategory != null ? [_selectedCategory!] : [],
          imageUrls: [], // Clear existing URLs as we're sending all images
        ),
        latitude: latitude,
        longitude: longitude,
        type: ListingType.Property,
        user: user,
        isFavourite: widget.existingListing?.isFavourite ?? false,
        imageUrls: [], // Clear existing URLs as we're sending all images
      );

      if (widget.existingListing != null) {
        final updatedListing = await context
            .read<PropertyProvider>()
            .updateProperty(listing, allImages);
        _showSuccessSnackBar('Property updated successfully');
        Navigator.pop(context, updatedListing); // Return the updated listing
        Navigator.pop(context);
      } else {
        final createdListing = await context
            .read<PropertyProvider>()
            .createProperty(listing, allImages);
        _showSuccessSnackBar('Property added successfully');
        Navigator.pop(context, createdListing); // Return the created listing
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _selectDate(BuildContext context, bool isMoveIn) async {
    if (isMoveIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Move-in Availability'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Available Anytime'),
                onTap: () {
                  setState(() {
                    _moveInDate = DateTime.now();
                    moveInDate = 'Anytime';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Select Specific Date'),
                onTap: () async {
                  Navigator.pop(context);
                  final DateTime? picked = await showMonthYearPicker(
                    context: context,
                    initialDate: _moveInDate ?? DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(Duration(days: 365 * 10)),
                    lastDate: DateTime.now().add(Duration(days: 365 * 10)),
                  );
                  if (picked != null) {
                    setState(() {
                      _moveInDate = picked;
                      moveInDate = DateFormat('yyyy-MM').format(picked);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else {
      final DateTime? picked = await showMonthYearPicker(
        context: context,
        initialDate: _moveOutDate ?? DateTime.now(),
        firstDate: DateTime.now().subtract(Duration(days: 365 * 10)),
        lastDate: DateTime.now().add(Duration(days: 365 * 10)),
      );
      if (picked != null) {
        setState(() {
          _moveOutDate = picked;
          moveOutDate = DateFormat('yyyy-MM').format(picked);
        });
      }
    }
  }

  Future<DateTime?> showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = initialDate;
        int selectedYear = selectedDate.year;
        int selectedMonth = selectedDate.month;

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Select Month and Year'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year Picker
                  DropdownButton<int>(
                    value: selectedYear,
                    items: List.generate(
                      lastDate.year - firstDate.year + 1,
                      (index) => DropdownMenuItem(
                        value: firstDate.year + index,
                        child: Text((firstDate.year + index).toString()),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                  // Month Picker
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                            DateFormat('MMMM').format(DateTime(0, index + 1))),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context)
                      .pop(DateTime(selectedYear, selectedMonth));
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingListing != null
                        ? "Edit Property"
                        : "Add Property",
                    style: TextStyle(
                      color: orangeColor,
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
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter property title',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 24),
              Text(
                'Property Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blackTextColor,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCategoryChip('Apartment', Icons.apartment),
                  _buildCategoryChip('Villa', Icons.villa),
                  _buildCategoryChip('Shared House', Icons.house),
                  _buildCategoryChip('Hostel', Icons.hotel),
                ],
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
                validator: (value) =>
                    value!.isEmpty ? 'Please enter property details' : null,
              ),
              SizedBox(height: 24),
              _buildImageList(),
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
              SizedBox(height: 24),
              Text(
                'Rent Price',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blackTextColor,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter price',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a price' : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildPriceTypeButton('Monthly', true),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Property Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blackTextColor,
                ),
              ),
              SizedBox(height: 12),
              _buildFeatureCounter('Bedroom', _bedroomsController),
              SizedBox(height: 12),
              _buildFeatureCounter('Bathroom', _bathroomsController),
              SizedBox(height: 12),
              _buildFeatureCounter('Max Occupancy', _maxOccController),
              SizedBox(height: 24),
              Text(
                'Environment / Facilities',
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
                      ..._customFeatures
                          .map((feature) => _buildAmenityChip(feature)),
                      InkWell(
                        onTap: _showAddFeatureDialog,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 18, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Add Feature',
                                style: TextStyle(color: Colors.grey[600]),
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
              _buildAvailabilitySection(),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _handleSubmit(user!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text(
                          widget.existingListing != null
                              ? "Edit Lisiting"
                              : 'Add Property',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    PropertyCategory? getCategory() {
      switch (label) {
        case 'Apartment':
          return PropertyCategory.apartment;
        case 'Studio':
          return PropertyCategory.studio;
        case 'Furnished':
          return PropertyCategory.furnished;
        case 'House':
          return PropertyCategory.house;
        case 'Villa':
          return PropertyCategory.villa;
        case 'Room':
          return PropertyCategory.room;
        case 'Shared House':
          return PropertyCategory.sharedHouse;
        case 'Hostel':
          return PropertyCategory.hostel;

        default:
          return null;
      }
    }

    final category = getCategory();
    final isSelected = category != null && _selectedCategory == category;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          SizedBox(width: 8),
          Text(label.split('').first.toUpperCase() + label.substring(1)),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (category != null) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        }
      },
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : blackTextColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String label) {
    final isSelected = _selectedAmenities.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedAmenities.add(label);
          } else {
            _selectedAmenities.remove(label);
          }
        });
      },
      selectedColor: orangeColor.withOpacity(0.2),
      checkmarkColor: orangeColor,
      labelStyle: TextStyle(
        color: isSelected ? orangeColor : blackTextColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? orangeColor : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildFeatureCounter(String label, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.all(16),
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

  Widget _buildPriceTypeButton(String label, bool isMonthly) {
    return TextButton(
      onPressed: () {
        // Implement price type toggle logic
      },
      style: TextButton.styleFrom(
        backgroundColor:
            isMonthly ? Theme.of(context).primaryColor : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isMonthly ? Colors.white : blackTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        MapBoxAutoCompleteWidget(
          hint: "Enter property address",
          defaultLatitude: widget.existingListing?.latitude,
          defaultLongitude: widget.existingListing?.longitude,
          onSelect: (place) {
            setState(() {
              _addressController.text = place.placeName;
              latitude = place.geometry.coordinates[1];
              longitude = place.geometry.coordinates[0];
              // Update location with city and state
              _locationController.text =
                  '${place.city ?? ''}, ${place.state ?? ''}'.trim();
            });
          },
          limit: 5,
        ),
      ],
    );
  }

  void _showAddressSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapBoxAutoCompleteWidget(
          hint: "Search address",
          onSelect: (place) {
            setState(() {
              _addressController.text = place.placeName;
              latitude = place.geometry.coordinates[1];
              longitude = place.geometry.coordinates[0];
              _locationController.text = place.context
                  .firstWhere((item) => item.id.startsWith('place'))
                  .text;
            });
            Navigator.pop(context);
          },
          limit: 10,
        ),
      ),
    );
  }

  Widget _buildImageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Photos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackTextColor,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._existingImageUrls.asMap().entries.map(
                    (entry) =>
                        _buildExistingImagePreview(entry.value, entry.key),
                  ),
              ..._selectedImages.asMap().entries.map(
                    (entry) => _buildNewImagePreview(entry.value, entry.key),
                  ),
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: InkWell(
                        onTap: _pickImages,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 32,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImagePreview(String imageUrl, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _removingImages[index] == true ? 0.0 : 1.0,
      child: AnimatedScale(
        duration: Duration(milliseconds: 300),
        scale: _removingImages[index] == true ? 0.0 : 1.0,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _removingImages[index] = true;
                  });
                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _existingImageUrls.removeAt(index);
                      _removingImages.remove(index);
                    });
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewImagePreview(File image, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _addingImages[index] == true ? 0.0 : 1.0,
      child: AnimatedScale(
        duration: Duration(milliseconds: 300),
        scale: _addingImages[index] == true ? 0.0 : 1.0,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _removingImages[index] = true;
                  });
                  Future.delayed(Duration(milliseconds: 300), () {
                    setState(() {
                      _selectedImages.removeAt(index);
                      _removingImages.remove(index);
                    });
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackTextColor,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Move-in Date *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: moveInDate == null ? 'Required' : null,
                  ),
                  child: Text(
                    moveInDate ?? 'Select Date',
                    style: TextStyle(
                      color: moveInDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Move-out Date (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    moveOutDate ?? 'Select Date',
                    style: TextStyle(
                      color: moveOutDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
