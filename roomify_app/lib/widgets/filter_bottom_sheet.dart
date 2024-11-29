import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/providers/search_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  final String query;
  FilterBottomSheet({required this.query});
  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? selectedGender;
  RangeValues priceRange = RangeValues(0, 3000);
  List<String> selectedPropertyTypes = [];
  List<String> selectedAmenities = [];
  List<PropertyCategory> selectedCategories = [];
  String? selectedLocation;
  double proximityValue = 3;

  int numberOfBedrooms = 0;
  int numberOfBathrooms = 0;
  int maxOccupancy = 0;
  RangeValues ratingRange = RangeValues(0, 5);

  late FilterOptions _filters;
  @override
  void initState() {
    super.initState();
    // Initialize with current filters or default values
    _filters = context.read<SearchProvider>().currentFilters ??
        FilterOptions.defaultValues();

    // Set initial values based on current filters
    priceRange = RangeValues(_filters.minPrice ?? 0, _filters.maxPrice ?? 3000);
    selectedPropertyTypes = _filters.propertyTypes;
    selectedAmenities = _filters.amenities;
    selectedCategories = _filters.itemCategories
        .map((c) =>
            PropertyCategory.values.firstWhere((e) => e.displayName == c))
        .toList();
    numberOfBedrooms = _filters.numberOfBedrooms ?? 0;
    numberOfBathrooms = _filters.numberOfBathrooms ?? 0;
    maxOccupancy = _filters.maxOccupancy ?? 0;
    ratingRange = RangeValues(_filters.rating?.toDouble() ?? 0, 5);
  }

  void _resetFilters() {
    setState(() {
      _filters = FilterOptions.defaultValues();
      // Reset all local state variables
      priceRange = RangeValues(0, 3000);
      selectedPropertyTypes = [];
      selectedAmenities = [];
      selectedCategories = [];
      numberOfBedrooms = 0;
      numberOfBathrooms = 0;
      maxOccupancy = 0;
      ratingRange = RangeValues(0, 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter Options",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text("Reset"),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Filter Content
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.all(16),
                children: [
                  // Price Range Section
                  _buildPriceSection(),
                  _buildDivider(),

                  // Location Section
                  _buildDivider(),

                  // Property Types Section
                  _buildPropertySection(),
                  _buildDivider(),

                  SizedBox(width: 16),
                  Text('Rating',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                      '${ratingRange.start.round()} - ${ratingRange.end.round()} stars',
                      style: TextStyle(color: Colors.grey)),
                  RangeSlider(
                    values: ratingRange,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    labels: RangeLabels(
                      ratingRange.start.round().toString(),
                      ratingRange.end.round().toString(),
                    ),
                    onChanged: (values) => setState(() => ratingRange = values),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text('Bathrooms'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (numberOfBathrooms > 0) {
                            setState(() => numberOfBathrooms--);
                          }
                        },
                      ),
                      Text(
                        numberOfBathrooms.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() => numberOfBathrooms++);
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text('Bedrooms'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (numberOfBedrooms > 0) {
                            setState(() => numberOfBedrooms--);
                          }
                        },
                      ),
                      Text(
                        numberOfBedrooms.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() => numberOfBedrooms++);
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text('Max Occupancy'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (maxOccupancy > 0) {
                            setState(() => maxOccupancy--);
                          }
                        },
                      ),
                      Text(
                        maxOccupancy.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() => maxOccupancy++);
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  // Categories Section
                  _buildCategorySection(),
                  _buildDivider(),

                  // Apply Button
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        final filterOptions = FilterOptions(
                          minPrice: priceRange.start,
                          maxPrice: priceRange.end,
                          location: selectedLocation,
                          numberOfBedrooms:
                              numberOfBedrooms > 0 ? numberOfBedrooms : null,
                          numberOfBathrooms:
                              numberOfBathrooms > 0 ? numberOfBathrooms : null,
                          maxOccupancy: maxOccupancy > 0 ? maxOccupancy : null,
                          propertyTypes: selectedPropertyTypes,
                          amenities: selectedAmenities,
                          rating: ratingRange.start.toInt(),
                          itemCategories: selectedCategories
                              .map((c) => c.displayName)
                              .toList(),
                        );

                        context
                            .read<SearchProvider>()
                            .setFilterOptions(filterOptions);
                        context.read<SearchProvider>().search(widget.query);

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text("Apply Filters"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          '\$${priceRange.start.round()} - \$${priceRange.end.round()}',
          style: TextStyle(color: Colors.grey),
        ),
        RangeSlider(
          values: priceRange,
          min: 0,
          max: 3000,
          divisions: 99,
          labels: RangeLabels(
            '\$${priceRange.start.round()}',
            '\$${priceRange.end.round()}',
          ),
          onChanged: (values) => setState(() => priceRange = values),
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
      'Pool',
      'AC',
      'Furnished',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: propertyTypes
              .map((type) => FilterChip(
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
        SizedBox(height: 16),
        Text(
          'Amenities',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities
              .map((amenity) => FilterChip(
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

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PropertyCategory.values
              .map((category) => FilterChip(
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
                  ))
              .toList(),
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
}
