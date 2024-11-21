import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';

class FilterBottomSheet extends StatefulWidget {
  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedGender;
  RangeValues compatibilityRange = RangeValues(3, 5);
  List<String> selectedLifestylePreferences = [];
  double proximityValue = 3;
  String? selectedLocation;
  RangeValues priceRange = RangeValues(500, 1500);
  List<String> selectedPropertyTypes = [];
  List<String> selectedAmenities = [];
  List<String> selectedItemCategories = [];
  List<PropertyCategory> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Filter Options",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          IconButton(
                            icon: Icon(Icons.filter_list, color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      _buildGenderSection(),
                      _buildDivider(),
                      _buildCategorySection(),
                      _buildDivider(),
                      _buildCompatibilitySection(),
                      _buildDivider(),
                      _buildLifestylePreferencesSection(),
                      _buildDivider(),
                      _buildLocationSection(),
                      _buildDivider(),
                      _buildPriceSection(),
                      _buildDivider(),
                      _buildPropertySection(),
                      _buildDivider(),
                      _buildItemCategoriesSection(),
                    ],
                  ),
                ),
              ),
            ));
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: [
            _buildGenderChip('No Preference'),
            _buildGenderChip('Male'),
            _buildGenderChip('Female'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      children: [
        Text(
          'Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PropertyCategory.values.map((category) {
            return FilterChip(
              label: Text(category.displayName),
              selected: selectedCategories.contains(category),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedCategories.add(category);
                  } else {
                    selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String gender) {
    return ChoiceChip(
      label: Text(gender),
      selected: selectedGender == gender,
      onSelected: (selected) {
        setState(() {
          selectedGender = selected ? gender : null;
        });
      },
    );
  }

  Widget _buildCompatibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compatibility',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
            'Compatibility Rating ${compatibilityRange.start.round()} - ${compatibilityRange.end.round()} stars',
            style: TextStyle(color: Colors.grey)),
        RangeSlider(
          values: compatibilityRange,
          min: 0,
          max: 5,
          divisions: 5,
          labels: RangeLabels(
            compatibilityRange.start.round().toString(),
            compatibilityRange.end.round().toString(),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              compatibilityRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLifestylePreferencesSection() {
    final preferences = [
      'Cleanliness',
      'Study Habits',
      'Party',
      'Sleeping Schedule',
      'Smoking Habits',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lifestyle Preferences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: preferences.map((preference) {
            return FilterChip(
              label: Text(preference),
              selected: selectedLifestylePreferences.contains(preference),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedLifestylePreferences.add(preference);
                  } else {
                    selectedLifestylePreferences.remove(preference);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Proximity ${proximityValue.round()} miles',
            style: TextStyle(color: Colors.grey)),
        Slider(
          value: proximityValue,
          min: 1,
          max: 10,
          divisions: 9,
          label: '${proximityValue.round()} miles',
          onChanged: (value) {
            setState(() {
              proximityValue = value;
            });
          },
        ),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for a city or neighborhood...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(
            'Range \$${priceRange.start.round()} - \$${priceRange.end.round()}',
            style: TextStyle(color: Colors.grey)),
        RangeSlider(
          values: priceRange,
          min: 100,
          max: 10000,
          divisions: 99,
          labels: RangeLabels(
            '\$${priceRange.start.round()}',
            '\$${priceRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              priceRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPropertySection() {
    final propertyTypes = [
      'Apartments',
      'Shared Houses',
      'Studios',
      'Private Residences',
      'Rooms for Rent',
      'Hostels',
    ];

    final amenities = [
      'Wi-Fi',
      'Laundry',
      'Parking',
      'Gym',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Type', style: TextStyle(color: Colors.grey)),
        Wrap(
          spacing: 8,
          children: propertyTypes.map((type) {
            return FilterChip(
              label: Text(type),
              selected: selectedPropertyTypes.contains(type),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedPropertyTypes.add(type);
                  } else {
                    selectedPropertyTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text('Amenities', style: TextStyle(color: Colors.grey)),
        Wrap(
          spacing: 8,
          children: amenities.map((amenity) {
            return FilterChip(
              label: Text(amenity),
              selected: selectedAmenities.contains(amenity),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedAmenities.add(amenity);
                  } else {
                    selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildItemCategoriesSection() {
    final categories = [
      'Furniture',
      'Electronics',
      'Clothing',
      'Books',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Categories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('Type', style: TextStyle(color: Colors.grey)),
        Wrap(
          spacing: 8,
          children: categories.map((category) {
            return FilterChip(
              label: Text(category),
              selected: selectedItemCategories.contains(category),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedItemCategories.add(category);
                  } else {
                    selectedItemCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(),
    );
  }

  void _resetFilters() {
    setState(() {
      selectedGender = null;
      compatibilityRange = RangeValues(3, 5);
      selectedLifestylePreferences.clear();
      proximityValue = 3;
      selectedLocation = null;
      priceRange = RangeValues(500, 1500);
      selectedPropertyTypes.clear();
      selectedAmenities.clear();
      selectedItemCategories.clear();
    });
  }
}
