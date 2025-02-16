import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:screenshot/screenshot.dart';

class LocationPickerSheet extends StatefulWidget {
  final double lat;
  final double lng;
  final Function(double lat, double lng) onLocationSelected;

  LocationPickerSheet({
    required this.lat,
    required this.lng,
    required this.onLocationSelected,
  });

  @override
  _LocationPickerSheetState createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet>
    with TickerProviderStateMixin {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PointAnnotation? currentMarker;
  Point? selectedPoint;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingLocation = false;
  bool _isUpdatingLocation = false;
  final GlobalKey markerKey = GlobalKey();

  static const double MARKER_SIZE = 80;
  late AnimationController _markerAnimationController;
  late Animation<double> _markerAnimation;
  bool _isSearching = false;

  // Add this variable to track center position
  Point? mapCenter;

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _markerAnimation = CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.bounceOut,
    );
    mapCenter = Point(
      coordinates: Position(widget.lng, widget.lat),
    );
  }

  Future<Uint8List> loadMarkerImage() async {
    final screenshotController = ScreenshotController();
    final markerWidget = Container(
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
              "You are here",
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
          ),
        ],
      ),
    );

    // Wait for the screenshot to complete and return the image data
    final Uint8List imageBytes = await screenshotController.captureFromWidget(
      markerWidget,
      pixelRatio: 0.7,
    );

    return imageBytes;
  }

  Future<void> _addMarker(Point point) async {
    if (currentMarker != null) {
      await pointAnnotationManager?.delete(currentMarker!);
    }

    // Get the marker image bytes
    final Uint8List imageBytes = await loadMarkerImage();

    final options = PointAnnotationOptions(
      geometry: point,
      image: imageBytes,
      iconSize: 0.7,
      // Adjusted icon size
    );

    currentMarker = await pointAnnotationManager?.create(options);
    _markerAnimationController.forward(from: 0.0);
  }

  // Update _onMapTap to move the map instead of the marker
  void _onMapTap(MapContentGestureContext context) async {
    final coordinate = context.point.coordinates;
    final newCenter = Point(
      coordinates: Position(
        coordinate.lng,
        coordinate.lat,
      ),
    );

    await mapboxMap.flyTo(
      CameraOptions(
        center: newCenter,
        zoom: 14.0,
      ),
      MapAnimationOptions(duration: 500),
    );

    setState(() {
      mapCenter = newCenter;
    });
  }

  void _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await geo.Geolocator.getCurrentPosition();
      final newCenter = Point(
        coordinates: Position(position.longitude, position.latitude),
      );

      // Animate the camera to the new center
      await mapboxMap.flyTo(
        CameraOptions(
          center: newCenter,
          zoom: 14.0,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );

      setState(() => mapCenter = newCenter);
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
            '?access_token=$mapboxToken'
            '&types=address'
            '&limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data['features']);
        });
      }
    } catch (e) {
      print('Error searching places: $e');
    }

    setState(() => _isSearching = false);
  }

  // Update _selectPlace
  void _selectPlace(Map<String, dynamic> place) {
    final coordinates = List<double>.from(place['center']);
    final newCenter = Point(
      coordinates: Position(coordinates[0], coordinates[1]),
    );

    setState(() {
      mapCenter = newCenter;
      _searchResults = [];
      _searchController.text = place['place_name'];
    });

    mapboxMap.flyTo(
      CameraOptions(
        center: newCenter,
        zoom: 14,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  void _onMapCreated(MapboxMap map) async {
    setState(() {
      mapboxMap = map;
    });

    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: false,
        scrollEnabled: true,
        doubleTapToZoomInEnabled: true,
        doubleTouchToZoomOutEnabled: true,
        pinchToZoomEnabled: true,
        pitchEnabled: false,
        scrollMode: ScrollMode.HORIZONTAL_AND_VERTICAL,
      ),
    );

    pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    _addMarker(selectedPoint!);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Choose Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search address...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: _searchPlaces,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            title: Text(place['place_name'] ?? ''),
                            onTap: () => _selectPlace(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MapWidget(
                    cameraOptions: CameraOptions(
                      center: mapCenter,
                      zoom: 14,
                    ),
                    onMapCreated: _onMapCreated,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onTapListener: _onMapTap,
                    onCameraChangeListener: (data) {
                      final newCenter = data.cameraState.center;

                      setState(() {
                        mapCenter = Point(
                          coordinates: Position(
                            newCenter.coordinates.lng,
                            newCenter.coordinates.lat,
                          ),
                        );
                      });
                    },
                  ),
                  // Add static centered marker
                  if (mapCenter != null)
                    Container(
                      height: 200,
                      width: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title container
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                              "You are here",
                              style: TextStyle(
                                fontSize: 12,
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
                        ],
                      ),
                    )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: mapCenter != null && !_isUpdatingLocation
                      ? () async {
                          if (mapCenter != null) {
                            setState(() => _isUpdatingLocation = true);
                            try {
                              final lat = mapCenter!.coordinates.lat.toDouble();
                              final lng = mapCenter!.coordinates.lng.toDouble();
                              await widget.onLocationSelected(lat, lng);
                            } finally {
                              if (mounted) {
                                setState(() => _isUpdatingLocation = false);
                              }
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdatingLocation
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
