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
          return handler.next(options);
        },
        onError: (error, handler) {
          print('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Listing>> search({
    String? query,
    String type = 'Property',
    FilterOptions? filterOptions,
    double? userLat,
    double? userLng,
    double radius = 100.0,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        if (query != null && query.isNotEmpty) 'query': query,
        'type': type,
        if (userLat != null) 'userLatitude': userLat,
        if (userLng != null) 'userLongitude': userLng,
        'radius': radius,
      };

      if (filterOptions != null) {
        queryParams.addAll({
          if (filterOptions.rating != null) 'rating': filterOptions.rating,
          if (filterOptions.maxOccupancy != null)
            'maxOccupancy': filterOptions.maxOccupancy,
          if (filterOptions.bedrooms != null)
            'bedrooms': filterOptions.bedrooms,
          if (filterOptions.bathrooms != null)
            'bathrooms': filterOptions.bathrooms,
          if (filterOptions.gender != null) 'gender': filterOptions.gender,
          if (filterOptions.minPrice != null)
            'minPrice': filterOptions.minPrice,
          if (filterOptions.maxPrice != null)
            'maxPrice': filterOptions.maxPrice,
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

  Future<List<Listing>> getSearchSuggestions(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get(
        '/api/search/suggestions',
        queryParameters: {
          'query': query,
          'type': 'Property',
          if (latitude != null) 'userLatitude': latitude,
          if (longitude != null) 'userLongitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> suggestions = response.data['listings'];
        return suggestions.map((json) => Listing.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch suggestions');
      }
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }
}
