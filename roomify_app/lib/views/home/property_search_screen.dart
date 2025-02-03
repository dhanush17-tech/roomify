import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:screenshot/screenshot.dart';

// Price range filter chip widget
class PriceFilterChips extends StatelessWidget {
  final List<Listing> properties;
  final Function(double?, double?) onFilterSelected;
  final double? selectedMinPrice;
  final double? selectedMaxPrice;

  const PriceFilterChips({
    Key? key,
    required this.properties,
    required this.onFilterSelected,
    this.selectedMinPrice,
    this.selectedMaxPrice,
  }) : super(key: key);

  List<Map<String, double>> _generatePriceRanges() {
    if (properties.isEmpty) return [];

    // Get all prices, considering floor plans for professional listings
    List<double> allPrices = properties.map((listing) {
      if (listing.user?.isProfessional == true &&
          listing.property?.floorPlans != null &&
          listing.property!.floorPlans!.isNotEmpty) {
        return listing.property!.floorPlans!
            .map((plan) => plan.price)
            .reduce((curr, next) => curr < next ? curr : next);
      }
      return listing.price.toDouble();
    }).toList();

    // Sort prices and remove duplicates
    allPrices = allPrices.toSet().toList()..sort();

    // If we have 4 or fewer unique prices, create ranges based on actual prices
    if (allPrices.length <= 4) {
      return allPrices
          .map((price) => {
                'min': price,
                'max': price,
              })
          .toList();
    }

    // Calculate price ranges
    double minPrice = allPrices.first;
    double maxPrice = allPrices.last;
    double range = maxPrice - minPrice;

    // Create 4 price ranges
    List<Map<String, double>> ranges = [];

    if (range <= 500) {
      // For small ranges, create smaller increments
      double increment = range / 4;
      for (int i = 0; i < 4; i++) {
        ranges.add({
          'min': minPrice + (i * increment),
          'max': minPrice + ((i + 1) * increment),
        });
      }
    } else {
      // For larger ranges, round to nearest hundred
      double roundedMin = (minPrice / 500).floor() * 500;
      double roundedMax = (maxPrice / 500).ceil() * 500;
      double increment = (roundedMax - roundedMin) / 4;

      for (int i = 0; i < 4; i++) {
        ranges.add({
          'min': roundedMin + (i * increment),
          'max': roundedMin + ((i + 1) * increment),
        });
      }
    }

    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    final priceRanges = _generatePriceRanges();

    return Container(
      padding: EdgeInsets.only(top: 0),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" filter chip
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text('All'),
              selected: selectedMinPrice == null && selectedMaxPrice == null,
              onSelected: (selected) {
                if (selected) {
                  onFilterSelected(null, null);
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: orangeColor.withOpacity(0.2),
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedMinPrice == null && selectedMaxPrice == null
                    ? orangeColor
                    : Colors.black,
              ),
            ),
          ),

          ...priceRanges.map((range) {
            bool isSelected = selectedMinPrice == range['min'] &&
                selectedMaxPrice == range['max'];
            return Padding(
              padding: EdgeInsets.only(right: 12),
              child: FilterChip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                label: Text(range['min'] == range['max']
                    ? '\$${range['min']!.toInt()}'
                    : '\$${range['min']!.toInt()}-\$${range['max']!.toInt()}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onFilterSelected(range['min'], range['max']);
                  } else {
                    onFilterSelected(null, null);
                  }
                },
                backgroundColor: Colors.grey[200],
                selectedColor: orangeColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? orangeColor : Colors.black,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class FilterSheet extends StatefulWidget {
  final double? selectedMinPrice;
  final double? selectedMaxPrice;
  final int? selectedBedrooms;
  final int? selectedBathrooms;
  final double selectedRadius;
  final Function(double?, double?, int?, int?, double) onApplyFilters;

  const FilterSheet({
    Key? key,
    this.selectedMinPrice,
    this.selectedMaxPrice,
    this.selectedBedrooms,
    this.selectedBathrooms,
    required this.selectedRadius,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late RangeValues _priceRange;
  int? _bedrooms;
  int? _bathrooms;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.selectedMinPrice ?? 0,
      widget.selectedMaxPrice ?? 10000,
    );
    _bedrooms = widget.selectedBedrooms;
    _bathrooms = widget.selectedBathrooms;
    _radius = widget.selectedRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          SizedBox(height: 20),
          Text(
            'Bedrooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Any'),
                  selected: _bedrooms == null,
                  onSelected: (selected) {
                    setState(() {
                      _bedrooms = null;
                    });
                  },
                ),
                ...List.generate(5, (index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text('${index + 1}'),
                      selected: _bedrooms == index + 1,
                      onSelected: (selected) {
                        setState(() {
                          _bedrooms = selected ? index + 1 : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Bathrooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Any'),
                  selected: _bathrooms == null,
                  onSelected: (selected) {
                    setState(() {
                      _bathrooms = null;
                    });
                  },
                ),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text('${index + 1}'),
                      selected: _bathrooms == index + 1,
                      onSelected: (selected) {
                        setState(() {
                          _bathrooms = selected ? index + 1 : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Search Radius (miles)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radius.round()} miles',
            onChanged: (value) {
              setState(() {
                _radius = value;
              });
            },
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onApplyFilters(
                  _priceRange.start,
                  _priceRange.end,
                  _bedrooms,
                  _bathrooms,
                  _radius,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modify SearchBarWidget
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(String) onSubmitted;
  final VoidCallback onFilterTap;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'home_search_field',
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.only(left: 13),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  hintText: "Search for properties...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.filter_list, color: orangeColor),
                    onPressed: widget.onFilterTap,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the controller and focusNode here as they are managed by the parent
    super.dispose();
  }
}

// Custom marker widget
class MarkerWidget extends StatelessWidget {
  final String title;
  final int price;

  const MarkerWidget({
    Key? key,
    required this.title,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Location icon
          Icon(
            Icons.location_on_rounded,
            color: orangeColor,
            size: 56,
          ),
          // Price container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '\$${price}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchMapScreen extends StatefulWidget {
  final String query;

  SearchMapScreen({required this.query});

  @override
  _SearchMapScreenState createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late DraggableScrollableController _bottomSheetController;
  bool _showSuggestions = false;
  late AnimationController _suggestionsAnimationController;
  late Animation<double> _suggestionsAnimation;
  double? _selectedMinPrice;
  double? _selectedMaxPrice;
  int? _selectedBedrooms;
  int? _selectedBathrooms;
  double _selectedRadius = 10.0;

  @override
  void initState() {
    super.initState();
    _bottomSheetController = DraggableScrollableController();
    _searchFocusNode.requestFocus();

    // Initialize animation controller
    _suggestionsAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _suggestionsAnimation = CurvedAnimation(
      parent: _suggestionsAnimationController,
      curve: Curves.easeInOut,
    );

    // Load initial properties
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = context.read<ProfileProvider>();
      context.read<SearchProvider>().loadInitialProperties(
            profileProvider.latitude,
            profileProvider.longitude,
          );
    });

    if (widget.query.isNotEmpty) {
      _searchController.text = widget.query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authProvider = context.read<AuthProvider>();
        context.read<SearchProvider>().search(
              widget.query,
              searchLat: authProvider.latitude,
              searchLng: authProvider.longitude,
            );
      });
    }
  }

  void _updateSuggestionsVisibility(String query) {
    final authProvider = context.read<AuthProvider>();
    if (query.isNotEmpty) {
      setState(() => _showSuggestions = true);
      _suggestionsAnimationController.forward();
      context.read<SearchProvider>().getSearchSuggestions(
            query,
            searchLat: authProvider.latitude,
            searchLng: authProvider.longitude,
          );
    } else {
      _suggestionsAnimationController.reverse().then((_) {
        setState(() => _showSuggestions = false);
      });
      // Load initial properties when search is cleared
      context.read<SearchProvider>().loadInitialProperties(
            authProvider.latitude,
            authProvider.longitude,
          );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FilterSheet(
          selectedMinPrice: _selectedMinPrice,
          selectedMaxPrice: _selectedMaxPrice,
          selectedBedrooms: _selectedBedrooms,
          selectedBathrooms: _selectedBathrooms,
          selectedRadius: _selectedRadius,
          onApplyFilters: (minPrice, maxPrice, bedrooms, bathrooms, radius) {
            setState(() {
              _selectedMinPrice = minPrice;
              _selectedMaxPrice = maxPrice;
              _selectedBedrooms = bedrooms;
              _selectedBathrooms = bathrooms;
              _selectedRadius = radius;
            });
            _onSearchSubmitted(_searchController.text);
          },
        ),
      ),
    );
  }

  void _onSearchSubmitted(String query) {
    final profileProvider = context.read<ProfileProvider>();
    context.read<SearchProvider>().search(
          query,
          searchLat: profileProvider.latitude,
          searchLng: profileProvider.longitude,
          filterOptions: FilterOptions(
            minPrice: _selectedMinPrice,
            maxPrice: _selectedMaxPrice,
            bedrooms: _selectedBedrooms,
            bathrooms: _selectedBathrooms,
            radius: _selectedRadius,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.read<ProfileProvider>();
    return Scaffold(
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          return Stack(
            children: [
              Consumer<SearchProvider>(
                builder: (context, provider, _) {
                  return MapView(
                    properties: provider.searchResults,
                    latitude: profileProvider.latitude,
                    longitude: profileProvider.longitude,
                  );
                },
              ),
              Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 0),
                      child: SearchBarWidget(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _updateSuggestionsVisibility,
                        onSubmitted: _onSearchSubmitted,
                        onFilterTap: _showFilterSheet,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Add price filter chips
                  if (!_showSuggestions &&
                      searchProvider.searchResults.isNotEmpty)
                    PriceFilterChips(
                      properties: searchProvider.searchResults,
                      onFilterSelected: (min, max) {
                        setState(() {
                          _selectedMinPrice = min;
                          _selectedMaxPrice = max;
                        });
                        // Trigger search with new price filters
                        _onSearchSubmitted(_searchController.text);
                      },
                      selectedMinPrice: _selectedMinPrice,
                      selectedMaxPrice: _selectedMaxPrice,
                    ),
                  if (_showSuggestions)
                    AnimatedBuilder(
                      animation: _suggestionsAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              0, -20 * (1 - _suggestionsAnimation.value)),
                          child: Opacity(
                            opacity: _suggestionsAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Consumer<SearchProvider>(
                          builder: (context, provider, _) {
                            return ListView.builder(
                              padding: EdgeInsets.all(0),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: provider.searchSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion =
                                    provider.searchSuggestions[index];
                                return ListTile(
                                  leading:
                                      Icon(Icons.search, color: Colors.grey),
                                  title: Text(suggestion.title),
                                  onTap: () {
                                    _suggestionsAnimationController
                                        .reverse()
                                        .then((_) {
                                      setState(() => _showSuggestions = false);
                                    });
                                    _searchController.text = suggestion.title;
                                    _searchFocusNode.unfocus();
                                    context.read<SearchProvider>().search(
                                          suggestion.title,
                                          searchLat: context
                                              .read<ProfileProvider>()
                                              .latitude,
                                          searchLng: context
                                              .read<ProfileProvider>()
                                              .longitude,
                                        );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              DraggableScrollableSheet(
                controller: _bottomSheetController,
                initialChildSize: 0.3,
                minChildSize: 0.15,
                maxChildSize: 0.8,
                builder: (context, scrollController) =>
                    _buildResultsSheet(scrollController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultsSheet(ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          // Tab indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 10),
          // Results list
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Searching...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.searchResults.isEmpty) {
                  return Center(child: Text("No results found"));
                }
                final authProvider = context.read<AuthProvider>();

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  controller: scrollController,
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final property = provider.searchResults[index];
                    return PropertyCard(property, authProvider.latitude,
                        authProvider.longitude);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bottomSheetController.dispose();
    _suggestionsAnimationController.dispose();
    super.dispose();
  }
}

class MapView extends StatefulWidget {
  final List<Listing> properties;
  final double latitude;
  final double longitude;

  const MapView({
    Key? key,
    required this.properties,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _mapInitialized = false;
  Map<String, Listing> _markerIdToProperty = {};
  bool _initialLocationSet = false;

  @override
  void initState() {
    super.initState();
    // Set initial location flag
    _initialLocationSet = false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: MapWidget(
        key: ValueKey('mapbox_map'),
        cameraOptions: CameraOptions(
          center:
              Point(coordinates: Position(widget.longitude, widget.latitude)),
          zoom: 14,
        ),
        onMapCreated: _onMapCreated,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }

  Future<Uint8List> _widgetToImage(Listing listing) async {
    final minPriceFloorPlan = listing.user?.isProfessional == true
        ? getMinPriceFloorPlan(listing)
        : null;

    final screenshotController = ScreenshotController();
    final wrappedWidget = Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        height: 200,
        padding: EdgeInsets.all(8),
        child: MarkerWidget(
            title: listing.title,
            price: minPriceFloorPlan?.price.toInt() ?? listing.price.toInt()),
      ),
    );

    final bytes = await screenshotController.captureFromWidget(
      wrappedWidget,
      delay: Duration(milliseconds: 100),
      pixelRatio: 2.0,
    );
    return bytes;
  }

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _annotationManager = await map.annotations.createPointAnnotationManager();
    setState(() => _mapInitialized = true);

    // Add initial markers
    if (widget.properties.isNotEmpty) {
      await _addMarkers(widget.properties);
      _initialLocationSet = true;
    }
  }

  Future<void> _addMarkers(List<Listing> properties) async {
    if (_annotationManager == null || !_mapInitialized) return;

    try {
      // Clear existing markers
      await _annotationManager?.deleteAll();
      _markerIdToProperty.clear();

      for (var property in properties) {
        if (property.latitude == null || property.longitude == null) continue;

        try {
          final markerIcon = await _widgetToImage(property);

          final options = PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                property.longitude!,
                property.latitude!,
              ),
            ),
            image: markerIcon,
            iconSize: 1.0,
            iconOffset: [0, -20], // Offset to center the marker
          );

          final marker = await _annotationManager?.create(options);
          if (marker != null) {
            _markerIdToProperty[marker.id!] = property;
          }
        } catch (e) {
          print('Error adding marker for property ${property.id}: $e');
        }
      }

      // Update camera position if needed
      if (properties.isNotEmpty && _initialLocationSet) {
        await updateCameraPosition(properties);
      }
    } catch (e) {
      print('Error in _addMarkers: $e');
    }
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.properties, oldWidget.properties)) {
      _addMarkers(widget.properties);
    }
  }

  @override
  void dispose() {
    _annotationManager?.deleteAll();
    super.dispose();
  }

  _Bounds _calculateBounds(List<Listing> properties) {
    double minLng = double.infinity, maxLng = -double.infinity;
    double minLat = double.infinity, maxLat = -double.infinity;

    for (var property in properties) {
      if (property.longitude != null && property.latitude != null) {
        minLng = min(minLng, property.longitude!);
        maxLng = max(maxLng, property.longitude!);
        minLat = min(minLat, property.latitude!);
        maxLat = max(maxLat, property.latitude!);
      }
    }

    if (minLng == double.infinity) {
      final userLocation = context.read<AuthProvider>().user;
      final defaultLat = widget.latitude;
      final defaultLng = widget.longitude;

      return _Bounds(
        center: Point(coordinates: Position(defaultLng, defaultLat)),
        zoom: 12,
      );
    }

    final centerLng = (minLng + maxLng) / 2;
    final centerLat = (minLat + maxLat) / 2;

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final zoom = 14 - max(latDiff, lngDiff) * 5;

    return _Bounds(
      center: Point(coordinates: Position(centerLng, centerLat)),
      zoom: zoom.clamp(3, 18).toDouble(),
    );
  }

  Future<void> updateCameraPosition(List<Listing> properties) async {
    if (properties.isNotEmpty) {
      final bounds = _calculateBounds(properties);
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: bounds.center,
          zoom: bounds.zoom,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }
}

class _Bounds {
  final Point center;
  final double zoom;

  _Bounds({required this.center, required this.zoom});
}
