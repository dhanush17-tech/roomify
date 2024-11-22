import 'package:dio/dio.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';

class SearchRepository {
  final Dio _dio;

  SearchRepository() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to header
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
  Future<List<Property>> search({
    required String query,
    required String type,
    FilterOptions? filterOptions,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'query': query,
        'type': type,
      };

      if (filterOptions != null) {
        if (filterOptions.rating != null) {
          queryParams['rating'] = filterOptions.rating.toString();
        }
        if (filterOptions.maxOccupancy != null) {
          queryParams['maxOccupancy'] = filterOptions.maxOccupancy.toString();
        }
        if (filterOptions.numberOfBedrooms != null) {
          queryParams['numberOfBedrooms'] =
              filterOptions.numberOfBedrooms.toString();
        }
        if (filterOptions.numberOfBathrooms != null) {
          queryParams['numberOfBathrooms'] =
              filterOptions.numberOfBathrooms.toString();
        }
        if (filterOptions.gender != null) {
          queryParams['gender'] = filterOptions.gender;
        }
        if (filterOptions.minPrice != null) {
          queryParams['minPrice'] = filterOptions.minPrice.toString();
        }
        if (filterOptions.maxPrice != null) {
          queryParams['maxPrice'] = filterOptions.maxPrice.toString();
        }
        if (filterOptions.location != null) {
          queryParams['location'] = filterOptions.location;
        }
        if (filterOptions.propertyTypes.isNotEmpty) {
          queryParams['propertyTypes'] = filterOptions.propertyTypes.join(',');
        }
        if (filterOptions.amenities.isNotEmpty) {
          queryParams['amenities'] = filterOptions.amenities.join(',');
        }
        if (filterOptions.itemCategories.isNotEmpty) {
          queryParams['categories'] = filterOptions.itemCategories.join(',');
        }
      }

      final response = await _dio.get(
        '/api/search',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Explicitly cast the response data to List<dynamic>
        final List<dynamic> results = response.data['results'] as List<dynamic>;

        // Convert each item to Property
        return results
            .map((json) => Property.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to search: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }
}
