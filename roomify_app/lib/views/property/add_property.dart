import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/widgets/mapbox_widget.dart';

class AddPropertyScreen extends StatefulWidget {
  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _maxOccController = TextEditingController();
  final List<String> _selectedAmenities = [];
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  final List<PropertyCategory> _selectedCategories = [];
  bool isLookingForRoomate = false;
  final _addressController = TextEditingController();
  double? latitude;
  double? longitude;

  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _handleSubmit(User user) async {
    if (!_formKey.currentState!.validate()) return;

    // Validation checks
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please add at least one image');
      return;
    }
    if (_selectedCategories.isEmpty) {
      _showErrorSnackBar('Please select at least one category');
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

    setState(() => _isLoading = true);

    try {
      final listing = Listing(
        createdAt: DateTime.now(),
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
        ),
        latitude: latitude,
        longitude: longitude,
        type: ListingType.Property,
        user: user,
        isFavourite: false,
        imageUrls: [],
        id: DateTime.now().millisecondsSinceEpoch + DateTime.now().millisecond,
      );

      await context.read<PropertyProvider>().createProperty(
            listing,
            _selectedImages,
          );

      _showSuccessSnackBar('Property added successfully');
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Images Section
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _buildAddImageButton();
                  }
                  return _buildImagePreview(_selectedImages[index], index);
                },
              ),
            ),

            SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter property title',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 5) {
                  return 'Title must be at least 5 characters long';
                }
                if (value.length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Describe your property',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 20) {
                  return 'Description must be at least 20 characters long';
                }
                if (value.length > 1000) {
                  return 'Description must be less than 1000 characters';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Location and Price

            SizedBox(
              height: 10,
            ),
            // Number of Rooms
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of Bedrooms',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter number of bedrooms',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final bedrooms = int.tryParse(value);
                      if (bedrooms == null) {
                        return 'Please enter a valid number';
                      }
                      if (bedrooms <= 0) {
                        return 'Must have at least 1 bedroom';
                      }
                      if (bedrooms > 20) {
                        return 'Number seems too high';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of Bathrooms',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter number of bathrooms',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final bathrooms = int.tryParse(value);
                      if (bathrooms == null) {
                        return 'Please enter a valid number';
                      }
                      if (bathrooms <= 0) {
                        return 'Must have at least 1 bathroom';
                      }
                      if (bathrooms > 20) {
                        return 'Number seems too high';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            TextFormField(
              controller: _maxOccController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Max Occupancy',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter maximum number of occupants',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final occupancy = int.tryParse(value);
                if (occupancy == null) {
                  return 'Please enter a valid number';
                }
                if (occupancy <= 0) {
                  return 'Must allow at least 1 occupant';
                }
                if (occupancy > 50) {
                  return 'Number seems too high';
                }
                return null;
              },
            ),
            SizedBox(
              height: 20,
            ),
            // Amenities
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                'Wi-Fi',
                'Parking',
                'Gym',
                'Pool',
                'Laundry',
                'AC',
                'Security',
                'Furnished',
              ]
                  .map((amenity) => FilterChip(
                        label: Text(amenity),
                        selected: _selectedAmenities.contains(amenity),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            SizedBox(height: 20),

            // Categories Section
            _buildAddressField(),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price/month',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixText: '\$',
                      hintText: 'Enter monthly rent',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      final price = int.tryParse(value);
                      if (price == null) {
                        return 'Please enter a valid number';
                      }
                      if (price <= 0) {
                        return 'Price must be greater than 0';
                      }
                      if (price > 1000000) {
                        return 'Price seems too high';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PropertyCategory.values.map((category) {
                return FilterChip(
                  label: Text(category.displayName),
                  selected: _selectedCategories.contains(category),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Text(
                  'Will you be living with the roommate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Checkbox(
                  value: isLookingForRoomate,
                  onChanged: (value) {
                    setState(() {
                      isLookingForRoomate = value!;
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _handleSubmit(context.read<AuthProvider>().user!),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Add Property'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        MapBoxAutoCompleteWidget(
          apiKey: mapboxToken,
          hint: "Enter property address",
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
          apiKey: mapboxToken,
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

  Widget _buildAddImageButton() {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: 100,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.add_photo_alternate, size: 40),
      ),
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedImages.removeAt(index);
              });
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
