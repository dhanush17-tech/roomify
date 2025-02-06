import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';

class SearchRepository {
  final Dio _dio;

  SearchRepository() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthRepository().getToken();
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<Listing>> search({
    String? query,
    String type = 'Property',
    FilterOptions? filterOptions,
    double? searchLatitude,
    double? searchLongitude,
    double radius = 100.0,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        if (query != null && query.isNotEmpty) 'query': query,
        'type': type,
        if (searchLatitude != null) 'userLatitude': searchLatitude.toString(),
        if (searchLongitude != null) 'userLongitude': searchLongitude.toString(),
        'radius': radius.toString(),
      };

      if (filterOptions != null) {
        queryParams.addAll({
          if (filterOptions.rating != null)
            'rating': filterOptions.rating.toString(),
          if (filterOptions.maxOccupancy != null)
            'maxOccupancy': filterOptions.maxOccupancy.toString(),
          if (filterOptions.bedrooms != null)
            'bedrooms': filterOptions.bedrooms.toString(),
          if (filterOptions.bathrooms != null)
            'bathrooms': filterOptions.bathrooms.toString(),
          if (filterOptions.gender != null) 'gender': filterOptions.gender,
          if (filterOptions.minPrice != null)
            'minPrice': filterOptions.minPrice.toString(),
          if (filterOptions.maxPrice != null)
            'maxPrice': filterOptions.maxPrice.toString(),
          if (filterOptions.location != null)
            'location': filterOptions.location,
          if (filterOptions.propertyTypes.isNotEmpty)
            'propertyTypes': filterOptions.propertyTypes.join(','),
          if (filterOptions.amenities.isNotEmpty)
            'amenities': filterOptions.amenities.join(','),
          if (filterOptions.itemCategories.isNotEmpty)
            'categories': filterOptions.itemCategories.join(','),
        });
      }

      final response = await _dio.get(
        '/api/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results.map((json) => Listing.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }

  Future<Map<String, dynamic>> getSuggestions(String query) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await http.get(
        Uri.https(baseUrl.replaceAll('https://', ''), 'api/search/suggestions',
            {'query': query}),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'locations': (data['locations'] as List)
              .map((location) => {
                    'id': location['id'],
                    'name': location['name'],
                    'full_name': location['full_name'],
                    'type': location['type'],
                    'coordinates': location['coordinates'],
                    'context': location['context'],
                  })
              .toList(),
          'properties': (data['properties'] as List)
              .map((property) => {
                    'id': property['id'].toString(),
                    'title': property['title'],
                    'location': property['location'],
                  })
              .toList(),
        };
      }
      throw Exception('Failed to get suggestions');
    } catch (e) {
      print('Error getting suggestions: $e');
      return {
        'locations': <Map<String, dynamic>>[],
        'properties': <Map<String, dynamic>>[],
      };
    }
  }
}

class LocationSuggestion {
  final String id;
  final String name;
  final String fullName;
  final String type;
  final List<double> coordinates;
  final String? context;

  LocationSuggestion({
    required this.id,
    required this.name,
    required this.fullName,
    required this.type,
    required this.coordinates,
    this.context,
  });

  double get latitude => coordinates[1];
  double get longitude => coordinates[0];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'full_name': fullName,
        'type': type,
        'coordinates': coordinates,
        'context': context,
      };

  @override
  String toString() => fullName;
}

class PropertySuggestion {
  final String id;
  final String title;
  final String? location;

  PropertySuggestion({
    required this.id,
    required this.title,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'location': location,
      };

  @override
  String toString() => title + (location != null ? ' ($location)' : '');
}
