import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/widgets/mapbox_widget.dart';
import 'package:roomify_app/utils/colors.dart';

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
  bool _isLoading = false;

  final List<String> _availableCategories = [
    'Furniture',
    'Electronics',
    'Books',
    'Clothing',
    'Kitchen',
    'Other'
  ];

  final Map<int, bool> _removingImages = {};
  final Map<int, bool> _addingImages = {};

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

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
  }

  Widget _buildImageList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Photos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          direction: Axis.horizontal,
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedImages.asMap().entries.map(
                  (entry) => _buildImagePreview(entry.value, entry.key),
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
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: _addingImages[index] == true ? 0.0 : 1.0,
      child: AnimatedScale(
        duration: Duration(milliseconds: 300),
        scale: _addingImages[index] == true ? 0.0 : 1.0,
        child: Container(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
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
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: blueColor,
                      size: 16,
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

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategories.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedCategories.add(label);
          } else {
            _selectedCategories.remove(label);
          }
        });
      },
      selectedColor: orangeColor.withOpacity(0.2),
      checkmarkColor: orangeColor,
      labelStyle: TextStyle(
        color: isSelected ? orangeColor : Colors.black87,
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

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        SnackBar(
          content: Text('Item created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          "Add Item",
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
                      'Item Title',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter item title',
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
                      'Item Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter item description',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Item Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableCategories
                          .map((category) => _buildCategoryChip(category))
                          .toList(),
                    ),
                    SizedBox(height: 24),
                    _buildImageList(),
                    SizedBox(height: 24),
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    MapBoxAutoCompleteWidget(
                      hint: "Enter item location",
                      onSelect: (place) {
                        setState(() {
                          _locationController.text = place.placeName;
                          _latitude = place.geometry.coordinates[1];
                          _longitude = place.geometry.coordinates[0];
                        });
                      },
                      limit: 5,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
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
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Add Item',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
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
