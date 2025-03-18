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
import 'package:roomify_app/widgets/availability_section.dart';
import 'package:roomify_app/widgets/property_image_list.dart';
import 'package:roomify_app/widgets/category_chip.dart';
import 'package:roomify_app/widgets/amenity_chip.dart';

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
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
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
        _selectedCategory = PropertyCategory.values.firstWhere(
          (category) =>
              category.name ==
              widget.existingListing!.property!.categories.first,
          orElse: () => PropertyCategory.apartment,
        );
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
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill out all required fields');
      return;
    }

    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      _showErrorSnackBar('Please enter a description');
      return;
    }
    if (_locationController.text.isEmpty) {
      _showErrorSnackBar('Please enter a location');
      return;
    }
    if (_priceController.text.isEmpty) {
      _showErrorSnackBar('Please enter a price');
      return;
    }
    if (_bedroomsController.text.isEmpty || _bedroomsController.text == '0') {
      _showErrorSnackBar('Please enter the number of bedrooms');
      return;
    }
    if (_bathroomsController.text.isEmpty || _bathroomsController.text == '0') {
      _showErrorSnackBar('Please enter the number of bathrooms');
      return;
    }
    if (_maxOccController.text.isEmpty || _maxOccController.text == '0') {
      _showErrorSnackBar('Please enter the maximum occupancy');
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
    if (latitude == null || longitude == null) {
      _showErrorSnackBar('Please select a valid address');
      return;
    }
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      _showErrorSnackBar('Please upload at least one image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<File> newImages = [];
      List<String> deletedImageUrls = [];

      for (String url in widget.existingListing?.property?.imageUrls ?? []) {
        if (!_existingImageUrls.contains(url)) {
          deletedImageUrls.add(url);
        }
      }

      // Add only new images that were selected
      for (File image in _selectedImages) {
        if (!_existingImageUrls.contains(image.path)) {
          newImages.add(image);
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
          walkScore: 0,
          transitScore: 0,
          transitDetails: {},
          numberOfBathrooms: int.parse(_bathroomsController.text),
          numberOfBedrooms: int.parse(_bedroomsController.text),
          amenities: _selectedAmenities,
          isLookingForRoomate: isLookingForRoomate,
          maxOccupancy: int.parse(_maxOccController.text),
          moveInDate: moveInDate!,
          moveOutDate: moveOutDate,
          categories:
              _selectedCategory != null ? [_selectedCategory!.name] : [],
          imageUrls: [], // Clear existing URLs as we're sending all images
          isRoomifyChoice:
              widget.existingListing?.property?.isRoomifyChoice ?? false,
          floorPlans: widget.existingListing?.property?.floorPlans ?? [],
        ),
        latitude: latitude,
        longitude: longitude,
        type: ListingType.Property,
        user: user,
        isFavorite: widget.existingListing?.isFavorite ?? false,
        imageUrls: [], // Clear existing URLs as we're sending all images
      );

      if (widget.existingListing != null) {
        final updatedListing =
            await context.read<PropertyProvider>().updateProperty(
                  listing,
                  newImages: newImages,
                  deletedImageUrls: deletedImageUrls,
                );
        _showSuccessSnackBar('Property updated successfully');
        if (mounted) {
          Navigator.of(context).pop(updatedListing);
        }
      } else {
        final createdListing =
            await context.read<PropertyProvider>().createProperty(
                  listing,
                  images: newImages,
                );
        _showSuccessSnackBar('Property added successfully');
        if (mounted) {
          Navigator.of(context).pop(createdListing);
        }
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

  void _selectDate(BuildContext context, bool isMoveIn, bool isAnytime) async {
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
              // // Text(
              // //   'Property Category',
              // //   style: TextStyle(
              // //     fontSize: 20,
              // //     fontWeight: FontWeight.bold,
              // //     color: blackTextColor,
              // //   ),
              // // ),
              // // SizedBox(height: 12),
              // // Wrap(
              // //   spacing: 12,
              // //   runSpacing: 12,
              // //   children: [
              // //     _buildCategoryChip('Apartment', Icons.apartment),
              // //     _buildCategoryChip('Villa', Icons.villa),
              // //     _buildCategoryChip('Shared House', Icons.house),
              // //     _buildCategoryChip('Hostel', Icons.hotel),
              // //   ],
              // // ),
              // SizedBox(height: 12),
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
              PropertyImageList(
                selectedImages: _selectedImages,
                existingImageUrls: _existingImageUrls,
                onImagesChanged: (images) {
                  setState(() {
                    _selectedImages = images;
                  });
                },
                onExistingImagesChanged: (urls) {
                  setState(() {
                    _existingImageUrls = urls;
                  });
                },
              ),
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
              _buildFeatureCounter('Number of Occupants', _maxOccController),
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
              AvailabilitySection(
                moveInDate: moveInDate,
                moveOutDate: moveOutDate,
                onSelectDate: _selectDate,
                onClearMoveOutDate: (value) {
                  setState(() {
                    moveOutDate = value;
                  });
                },
              ),
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
                      ? Center(child: CircularProgressIndicator())
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
    final isSelected = _selectedCategory?.name == label;
    return CategoryChip(
      label: label,
      icon: icon,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedCategory = isSelected
              ? null
              : PropertyCategory.values.firstWhere(
                  (cat) => cat.name == label,
                  orElse: () => PropertyCategory.apartment,
                );
        });
      },
    );
  }

  Widget _buildAmenityChip(String label) {
    final isSelected = _selectedAmenities.contains(label);
    return AmenityChip(
      label: label,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedAmenities.remove(label);
          } else {
            _selectedAmenities.add(label);
          }
        });
      },
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
}
