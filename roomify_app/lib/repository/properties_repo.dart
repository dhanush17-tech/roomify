import 'dart:io';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';

class PropertyRepository {
  final Dio _dio;

  PropertyRepository() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthRepository().getToken();
          options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
      ),
    );
  }

  Future<List<Property>> getRecommendedListings(
      double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/api/properties/recommended-listings',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': 200, // Default 10km radius
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results
            .map((json) => Property.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch recommendations');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<List<Property>> getPairUpListings() async {
    try {
      final response = await _dio.get('/api/properties/pair-up');

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results
            .map((json) => Property.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch pair-up listings');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<String> createProperty(Property property, List<File> images) async {
    try {
      final formData = FormData.fromMap({
        ...property.toJson(),
        'images': images
            .map((image) => MultipartFile.fromFileSync(
                  image.path,
                  filename: image.path.split('/').last,
                ))
            .toList(),
      });

      final response = await _dio.post(
        '/api/properties',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['propertyId'].toString();
      } else {
        throw Exception('Failed to create property');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
