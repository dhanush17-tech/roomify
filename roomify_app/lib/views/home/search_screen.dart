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

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
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
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onEditingComplete: () {
                  widget.focusNode.unfocus();
                  widget.onChanged(widget.controller.text);
                },
                decoration: InputDecoration(
                  hintText: "Search for furniture, books...",
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
  final String price;

  const MarkerWidget({
    Key? key,
    required this.title,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
            '\$$price',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class SearchMapScreen extends StatefulWidget {
  final String query;

  SearchMapScreen({required this.query});

  @override
  _SearchMapScreenState createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late DraggableScrollableController _bottomSheetController;

  @override
  void initState() {
    super.initState();
    _bottomSheetController = DraggableScrollableController();
    _searchFocusNode.requestFocus();
    if (widget.query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SearchProvider>().search(widget.query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resize when keyboard appears
      body: Stack(
        children: [
          Consumer<SearchProvider>(
            builder: (context, provider, _) {
              return MapView(properties: provider.searchResults);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SearchBarWidget(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (query) {
                    // Use a debouncer to prevent too frequent searches
                    Future.delayed(Duration(milliseconds: 500), () {
                      if (mounted && query == _searchController.text) {
                        context.read<SearchProvider>().search(query);
                      }
                    });
                  },
                );
              },
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
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  controller: scrollController,
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final property = provider.searchResults[index];
                    return PropertyCard(listing: property);
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
    super.dispose();
  }
}

class MapView extends StatefulWidget {
  final List<Listing> properties;

  const MapView({Key? key, required this.properties}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with SingleTickerProviderStateMixin {
  late MapboxMap _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _mapInitialized = false;
  Map<String, Listing> _markerIdToProperty = {};
  Future<void> _initializeMap() async {
    try {
      if (!_mapInitialized) return;

      _annotationManager =
          await _mapboxMap.annotations.createPointAnnotationManager();
      _updateMarkersAndCamera(widget.properties);
    } catch (e) {
      debugPrint("Map initialization error: $e");
      // Handle error appropriately
    }
  }

  Future<Uint8List> _widgetToImage(Widget widget) async {
    final double width = 200;
    final double height = 200;

    final GlobalKey repaintBoundaryKey = GlobalKey();
    final Widget wrappedWidget = RepaintBoundary(
      key: repaintBoundaryKey,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: widget,
          ),
        ),
      ),
    );

    // Create an overlay entry to actually render the widget
    final overlayEntry = OverlayEntry(
      builder: (context) => wrappedWidget,
    );

    // Insert the overlay entry into the current overlay
    Overlay.of(context).insert(overlayEntry);

    // Wait for the widget to be rendered
    await Future.delayed(Duration(milliseconds: 100));

    try {
      // Now we can safely access the RenderRepaintBoundary
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Failed to find render boundary");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      return byteData.buffer.asUint8List();
    } finally {
      // Always remove the overlay entry
      overlayEntry.remove();
    }
  }

  void _handleMarkerTap(PointAnnotation annotation) {
    final property = _markerIdToProperty[annotation.id];
    if (property != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyDetailsScreen(property),
        ),
      );
    }
  }

  void _updateMarkersAndCamera(List<Listing> properties) async {
    if (_annotationManager == null || !_mapInitialized) return;

    try {
      // Clear existing markers
      await _annotationManager!.deleteAll();
      _markerIdToProperty.clear();

      // Load marker icon once

      // Create all marker options at once
      var options = <PointAnnotationOptions>[];

      for (var property in properties) {
        ScreenshotController screenshotController = ScreenshotController();

        final wrappedWidget = Container(
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
                  property.title,
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
                  '\$${property.price}',
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

        await screenshotController
            .captureFromWidget(wrappedWidget)
            .then((Uint8List? image) {
          if (property.latitude != null && property.longitude != null) {
            options.add(
              PointAnnotationOptions(
            
                  geometry: Point(
                    coordinates: Position(
                      property.longitude!,
                      property.latitude!,
                    ),
                  ),
                  image: image,
                  iconSize: 0.75),
            );
          }
        });
      }

      // Create all markers at once
      final markers = await _annotationManager?.createMulti(options);

      // Store property references
      if (markers != null) {
        for (var i = 0; i < markers.length; i++) {
          _markerIdToProperty[markers[i]!.id!] = properties[i];
        }
      }

      // Update camera to show all markers
      if (properties.isNotEmpty) {
        final bounds = _calculateBounds(properties);
        await _mapboxMap.flyTo(
          CameraOptions(
            center: bounds.center,
            zoom: bounds.zoom,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    } catch (e) {
      debugPrint("Error updating markers: $e");
    }
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
      // Get user's location from AuthProvider
      final userLocation = context.read<AuthProvider>().user;
      final defaultLat = userLocation?.latitude ?? 12.9716;
      final defaultLng = userLocation?.longitude ?? 77.6441;

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

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.properties != oldWidget.properties) {
      _updateMarkersAndCamera(widget.properties);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user's location from AuthProvider
    final userLocation = context.read<AuthProvider>().user;
    final defaultLat = userLocation?.latitude ??
        12.9716; // Default to Bangalore if no location
    final defaultLng = userLocation?.longitude ?? 77.6441;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: MapWidget(
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(defaultLng, defaultLat)),
          zoom: 12,
        ),
        onMapCreated: (map) async {
          _mapboxMap = map;
          // Wait for map to be fully loaded
        },
        onStyleLoadedListener: (d) async {
          print("Map style loaded");
          setState(() {
            _mapInitialized = true;
          });
          await _initializeMap();
        },
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
      ),
    );
  }
}

class _Bounds {
  final Point center;
  final double zoom;

  _Bounds({required this.center, required this.zoom});
}
