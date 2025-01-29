import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomify_app/utils/colors.dart';

class PropertyImageList extends StatefulWidget {
  final List<File> selectedImages;
  final List<String> existingImageUrls;
  final Function(List<File>) onImagesChanged;
  final Function(List<String>) onExistingImagesChanged;

  const PropertyImageList({
    Key? key,
    required this.selectedImages,
    required this.existingImageUrls,
    required this.onImagesChanged,
    required this.onExistingImagesChanged,
  }) : super(key: key);

  @override
  _PropertyImageListState createState() => _PropertyImageListState();
}

class _PropertyImageListState extends State<PropertyImageList> {
  final Map<int, bool> _removingImages = {};
  final Map<int, bool> _addingImages = {};

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70, // Compress images for better performance
      );

      if (images.isNotEmpty) {
        final newImages = images.map((image) => File(image.path)).toList();
        setState(() {
          for (var i = 0; i < newImages.length; i++) {
            _addingImages[widget.selectedImages.length + i] = true;
          }
        });

        widget.onImagesChanged([...widget.selectedImages, ...newImages]);

        await Future.delayed(Duration(milliseconds: 50));

        setState(() {
          for (var i = widget.selectedImages.length - newImages.length;
              i < widget.selectedImages.length;
              i++) {
            _addingImages.remove(i);
          }
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  void _removeImage(int index, bool isExisting) async {
    setState(() {
      _removingImages[index] = true;
    });

    await Future.delayed(Duration(milliseconds: 300));

    if (isExisting) {
      final newUrls = List<String>.from(widget.existingImageUrls);
      newUrls.removeAt(index);
      widget.onExistingImagesChanged(newUrls);
    } else {
      final newImages = List<File>.from(widget.selectedImages);
      newImages.removeAt(index);
      widget.onImagesChanged(newImages);
    }

    setState(() {
      _removingImages.remove(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Images',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackTextColor,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add Image Button
              InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 32, color: Colors.grey[600]),
                      SizedBox(height: 4),
                      Text(
                        'Add Images',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Existing Images
              ...widget.existingImageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: _removingImages[index] == true ? 0.0 : 1.0,
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 100,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.error),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeImage(index, true),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // Selected Images
              ...widget.selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: _removingImages[index] == true
                      ? 0.0
                      : _addingImages[index] == true
                          ? 0.0
                          : 1.0,
                  child: Container(
                    width: 100,
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image,
                            width: 100,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeImage(index, false),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
