import 'dart:convert';
import 'dart:io';
import "package:http/http.dart" as http;
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:roomify_app/models/itemModel.dart';
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

  Future<List<Listing>> getRecommendedListings(
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
            .map((json) => Listing.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch recommendations');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<List<Listing>> getPairUpListings() async {
    try {
      final response = await _dio.get('/api/properties/pair-up');

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results
            .map((json) => Listing.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch pair-up listings');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<List<Listing>> getFavorites() async {
    try {
      final response = await _dio.get('$baseUrl/api/properties/favorites');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['favorites'];
        return data.map((json) => Listing.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load favorites');
      }
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  Future<Listing> createProperty(Listing listing, List<File> images) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/properties'));

      request.headers.addAll(_headers);
      request.fields['listing'] = jsonEncode(listing.toJson());

      // Add images
      for (var image in images) {
        final fileName = image.path.split('/').last;
        final stream = http.ByteStream(image.openRead());
        final length = await image.length();

        final multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: fileName,
        );

        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['listing'];
        return Listing.fromJson(data);
      } else {
        // Parse error message from response if available
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to create property';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      if (e is Exception) {
        throw e;
      }
      throw Exception('Failed to create property: $e');
    }
  }

  Future<List<Listing>> getProperties() async {
    final token = await AuthRepository().getToken();
    final _headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/properties'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['listings'];
        return data.map((item) => Listing.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      throw Exception('Failed to load properties: $e');
    }
  }

  Future<void> addFavorite(int listingId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/properties/favorites',
        data: json.encode({'listingId': listingId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add favorite');
      }
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(int listingId) async {
    try {
      final response = await _dio.delete(
        '$baseUrl/api/properties/favorites/$listingId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to remove favorite');
      }
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
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
