import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/widgets/mapbox_widget.dart';
 
class AddMarketplaceScreen extends StatefulWidget {
  @override
  _AddMarketplaceScreenState createState() => _AddMarketplaceScreenState();
}

class _AddMarketplaceScreenState extends State<AddMarketplaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  List<File> _selectedImages = [];
  List<String> _selectedCategories = [];
  double _latitude = 0.0;
  double _longitude = 0.0;

  final List<String> _availableCategories = [
    'Furniture',
    'Electronics',
    'Books',
    'Clothing',
    'Kitchen',
    'Other'
  ];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedImages.isNotEmpty) {
      try {
        final provider = context.read<MarketplaceProvider>();
        
        await provider.createMarketplaceItem(
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          location: _locationController.text,
          latitude: _latitude,
          longitude: _longitude,
          categories: _selectedCategories,
          images: _selectedImages,
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item created successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create item: $e')),
        );
      }
    }
  }

  void _handlePlaceSelection(Place place) {
    setState(() {
      _locationController.text = place.placeName;
      _latitude = place.geometry.coordinates[1]; // Mapbox returns [longitude, latitude]
      _longitude = place.geometry.coordinates[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Marketplace Item'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a price' : null,
              ),
              SizedBox(height: 16),
              MapBoxAutoCompleteWidget(
                 hint: "Enter location",
                onSelect: _handlePlaceSelection,
              ),
              SizedBox(height: 16),
              Text('Categories:'),
              Wrap(
                spacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
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
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImages,
                child: Text('Add Images'),
              ),
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Image.file(_selectedImages[index]),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Create Listing'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }
} 