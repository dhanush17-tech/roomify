import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/providers/search_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedGender;
  RangeValues compatibilityRange = RangeValues(3, 5);
  List<String> selectedLifestylePreferences = [];
  double proximity = 3;
  String? location;
  RangeValues priceRange = RangeValues(500, 1500);
  List<String> selectedPropertyTypes = [];
  List<String> selectedAmenities = [];
  List<String> selectedItemCategories = [];

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
        child: ListView(
          controller: controller,
          children: [
            Text('Filter Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            _buildGenderFilter(),
            _buildCompatibilityFilter(),
            _buildLifestylePreferences(),
            _buildLocationFilter(),
            _buildPriceFilter(),
            _buildPropertyTypeFilter(),
            _buildAmenitiesFilter(),
            _buildItemCategoriesFilter(),
            ElevatedButton(
              onPressed: () {
                final filterOptions = FilterOptions(
                  gender: selectedGender,
                  minCompatibility: compatibilityRange.start,
                  maxCompatibility: compatibilityRange.end,
                  lifestylePreferences: selectedLifestylePreferences,
                  proximity: proximity,
                  location: location,
                  minPrice: priceRange.start,
                  maxPrice: priceRange.end,
                  propertyTypes: selectedPropertyTypes,
                  amenities: selectedAmenities,
                  itemCategories: selectedItemCategories,
                );
                context.read<SearchProvider>().setFilterOptions(filterOptions);
                Navigator.pop(context);
              },
              child: Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Radio<String>(
              value: 'No Preference',
              groupValue: selectedGender,
              onChanged: (value) => setState(() => selectedGender = value),
            ),
            Text('No Preference'),
            Radio<String>(
              value: 'Male',
              groupValue: selectedGender,
              onChanged: (value) => setState(() => selectedGender = value),
            ),
            Text('Male'),
            Radio<String>(
              value: 'Female',
              groupValue: selectedGender,
              onChanged: (value) => setState(() => selectedGender = value),
            ),
            Text('Female'),
          ],
        ),
      ],
    );
  }

  Widget _buildCompatibilityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Compatibility', style: TextStyle(fontSize: 16)),
        RangeSlider(
          values: compatibilityRange,
          min: 0,
          max: 5,
          divisions: 5,
          labels: RangeLabels(
            compatibilityRange.start.toString(),
            compatibilityRange.end.toString(),
          ),
          onChanged: (values) {
            setState(() {
              compatibilityRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLifestylePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lifestyle Preferences', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8.0,
          children: [
            'Cleanliness',
            'Study Habits',
            'Party',
            'Sleeping Schedule',
            'Smoking Habits'
          ]
              .map((preference) => ChoiceChip(
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
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: TextStyle(fontSize: 16)),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for a city or neighborhood...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => location = value),
        ),
        SizedBox(height: 8),
        Text('Proximity: ${proximity.toString()} miles'),
        Slider(
          value: proximity,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (value) => setState(() => proximity = value),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price', style: TextStyle(fontSize: 16)),
        RangeSlider(
          values: priceRange,
          min: 100,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '\$${priceRange.start.toInt()}',
            '\$${priceRange.end.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              priceRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPropertyTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Type', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8.0,
          children: [
            'Apartments',
            'Shared Houses',
            'Studios',
            'Private Residences',
            'Rooms for Rent',
            'Hostels'
          ]
              .map((type) => ChoiceChip(
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
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8.0,
          children: ['Wi-Fi', 'Laundry', 'Parking', 'Gym']
              .map((amenity) => ChoiceChip(
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
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildItemCategoriesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Categories', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8.0,
          children: ['Furniture', 'Electronics', 'Clothing', 'Books']
              .map((category) => ChoiceChip(
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
                  ))
              .toList(),
        ),
      ],
    );
  }
}
