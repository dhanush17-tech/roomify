import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/utils.dart';

class LocationPickerSheet extends StatefulWidget {
  final double lat;
  final double lng;
  LocationPickerSheet({required this.lat, required this.lng});
  @override
  _LocationPickerSheetState createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PointAnnotation? currentMarker;
  Point? selectedPoint;
  Uint8List? markerImageBytes;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    loadMarkerImage();
    selectedPoint = Point(
      coordinates: Position(
        widget.lng,
        widget.lat,
      ),
    );
  }

  Future<void> loadMarkerImage() async {
    final ByteData bytes =
        await rootBundle.load('assets/icons/location_marker.png');
    setState(() {
      markerImageBytes = bytes.buffer.asUint8List();
    });
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search address...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: _searchPlaces,
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
              child: MapWidget(
                cameraOptions: CameraOptions(
                  center: selectedPoint,
                  zoom: 14,
                ),
                onMapCreated: _onMapCreated,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                onTapListener: _onMapTap,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed:
                    selectedPoint != null ? () => _saveLocation(context) : null,
                child: Text('Confirm Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(MapboxMap map) async {
    mapboxMap = map;

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

    if (markerImageBytes != null) {
      _addMarker(selectedPoint!);
    }
  }

  void _addMarker(Point point) async {
    if (markerImageBytes == null) return;

    if (currentMarker != null) {
      await pointAnnotationManager?.delete(currentMarker!);
    }

    final options = PointAnnotationOptions(
      geometry: point,
      image: markerImageBytes!,
      iconColor: 4294150523,
      iconSize: 0.06,
    );

    currentMarker = await pointAnnotationManager?.create(options);
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

  void _selectPlace(Map<String, dynamic> place) {
    final coordinates = List<double>.from(place['center']);
    final point = Point(
      coordinates: Position(coordinates[0], coordinates[1]),
    );

    setState(() {
      selectedPoint = point;
      _searchResults = [];
      _searchController.text = place['place_name'];
    });

    mapboxMap.flyTo(
        CameraOptions(
          center: point,
          zoom: 14,
        ),
        MapAnimationOptions());

    _addMarker(point);
  }

  void _onMapTap(MapContentGestureContext context) async {
    final coordinate = context.point.coordinates;
    setState(() {
      selectedPoint = Point(
        coordinates: Position(
          coordinate.lng,
          coordinate.lat,
        ),
      );
    });

    _addMarker(selectedPoint!);
  }

  Future<void> _saveLocation(BuildContext context) async {
    if (selectedPoint != null) {
      try {
        final lat = selectedPoint!.coordinates.lat;
        final lng = selectedPoint!.coordinates.lng;

        await context
            .read<ProfileProvider>()
            .updateLocation(lat as double, lng as double);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location: $e')),
        );
      }
    }
  }
}
