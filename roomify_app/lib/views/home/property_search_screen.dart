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
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:screenshot/screenshot.dart';

// Separate widget for the search bar to prevent unnecessary rebuilds
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final Function(String) onSubmitted;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
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

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _updateSuggestionsVisibility,
                  onSubmitted: (query) {
                    context.read<SearchProvider>().search(
                          query,
                          searchLat: profileProvider.latitude,
                          searchLng: profileProvider.longitude,
                        );
                  },
                ),
                SizedBox(height: 10),
                if (_showSuggestions)
                  AnimatedBuilder(
                    animation: _suggestionsAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset:
                            Offset(0, -20 * (1 - _suggestionsAnimation.value)),
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
                                leading: Icon(Icons.search, color: Colors.grey),
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
                                        searchLat: profileProvider.latitude,
                                        searchLng: profileProvider.longitude,
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

  Future<Uint8List> _widgetToImage(Listing property) async {
    final screenshotController = ScreenshotController();
    final wrappedWidget = Material(
      color: Colors.transparent,
      child: Container(
        width: 200,
        height: 200,
        padding: EdgeInsets.all(8),
        child:
            MarkerWidget(title: property.title, price: property.price.toInt()),
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
