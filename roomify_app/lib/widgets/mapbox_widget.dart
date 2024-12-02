import 'package:dio/dio.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roomify_app/utils.dart';

class MapBoxAutoCompleteWidget extends StatefulWidget {
   final String hint;
  final Function(Place) onSelect;
  final int limit;

  const MapBoxAutoCompleteWidget({
     required this.hint,
    required this.onSelect,
    this.limit = 5,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(Icons.location_on),
            suffixIcon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  leading: Icon(Icons.location_on_outlined),
                  title: Text(
                    place.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${place.city ?? ''}, ${place.state ?? ''}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
