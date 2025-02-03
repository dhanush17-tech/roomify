import 'package:dio/dio.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roomify_app/utils.dart';
import 'package:roomify_app/utils/colors.dart';

class MapBoxAutoCompleteWidget extends StatefulWidget {
  final String hint;
  final Function(Place) onSelect;
  final int limit;
  final double? defaultLatitude;
  final double? defaultLongitude;
  final InputDecoration? inputDecoration;

  const MapBoxAutoCompleteWidget({
    required this.hint,
    required this.onSelect,
    this.limit = 5,
    this.defaultLatitude,
    this.defaultLongitude,
    this.inputDecoration,
  });

  @override
  _MapBoxAutoCompleteWidgetState createState() =>
      _MapBoxAutoCompleteWidgetState();
}

class _MapBoxAutoCompleteWidgetState extends State<MapBoxAutoCompleteWidget> {
  final _searchController = TextEditingController();
  List<Place> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  late Dio _dio;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: 1000),
      receiveTimeout: Duration(seconds: 1000),
    ));

    if (widget.defaultLatitude != null && widget.defaultLongitude != null) {
      _reverseGeocode(widget.defaultLatitude!, widget.defaultLongitude!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    if (_dio.interceptors.isNotEmpty) {
      _dio.interceptors.clear(); // Prevent piling up interceptors
    }

    setState(() => _isLoading = true);

    try {
      final String endpoint =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json';

      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'access_token': mapboxToken,
          'limit': widget.limit,
        },
      );

      if (response.statusCode == 200) {
        final features = response.data['features'] as List;
        setState(() {
          _suggestions =
              features.map((feature) => Place.fromJson(feature)).toList();
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(double latitude, double longitude) async {
    setState(() => _isLoading = true);

    try {
      final String endpoint =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json';

      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'access_token': mapboxToken,
          'types': 'address',
        },
      );

      if (response.statusCode == 200 && response.data['features'].length > 0) {
        final place = Place.fromJson(response.data['features'][0]);
        _searchController.text = place.placeName;
        widget.onSelect(place);
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: widget.inputDecoration ??
              InputDecoration(
                hintText: widget.hint,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.location_on_outlined),
                suffixIcon: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(Duration(milliseconds: 500), () {
              _getSuggestions(value);
            });
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: blackTextColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[600],
                  ),
                  title: Text(
                    place.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: blackTextColor.withOpacity(0.8),
                    ),
                  ),
                  subtitle: Text(
                    '${place.city ?? ''}, ${place.state ?? ''}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    _searchController.text = place.placeName;
                    widget.onSelect(place);
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class Place {
  final String placeName;
  final Geometry geometry;
  final List<Context> context;
  final String? city; // Add city
  final String? state; // Add state

  Place({
    required this.placeName,
    required this.geometry,
    required this.context,
    this.city,
    this.state,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    String? city;
    String? state;

    // Extract city and state from context
    final contextList = json['context'] as List<dynamic>? ?? [];
    for (var item in contextList) {
      if (item['id'].toString().startsWith('place')) {
        city = item['text'];
      }
      if (item['id'].toString().startsWith('region')) {
        state = item['text'];
      }
    }

    return Place(
      placeName: json['place_name'] ?? '',
      geometry: Geometry.fromJson(json['geometry'] ?? {}),
      context: contextList.map((e) => Context.fromJson(e)).toList(),
      city: city,
      state: state,
    );
  }
}

class Geometry {
  final List<double> coordinates;

  Geometry({
    required this.coordinates,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      coordinates: json['coordinates'].cast<double>(),
    );
  }
}

class Context {
  final String id;
  final String text;

  Context({
    required this.id,
    required this.text,
  });

  factory Context.fromJson(Map<String, dynamic> json) {
    return Context(
      id: json['id'],
      text: json['text'],
    );
  }
}
