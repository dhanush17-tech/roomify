import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
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

  Future<List<Listing>> getRecommendedProperties(
      double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/api/properties/recommended-listings',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': 20, // Default 20km radius
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

  Future<List<Listing>> getPairUpProperties() async {
    try {
      final response = await _dio.get('/api/properties/pair-up');

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'];
        return results
            .map((json) => Listing.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch pair-up properties');
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

  Future<Listing> createProperty(Listing listing,
      {List<File> images = const []}) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/properties'),
      );
      request.headers.addAll(_headers);
      request.fields['listing'] = jsonEncode(listing.toJson());

      // Add images to the request
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
        return Listing.fromJson(json.decode(response.body)['listing']);
      } else {
        throw Exception('Failed to create property');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
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

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> reportProperty(
    int propertyId,
    String reason,
    String details,
  ) async {
    try {
      final response = await _dio.post(
        '/api/properties/report/$propertyId',
        data: {
          'reason': reason,
          'details': details,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to submit report');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 &&
          e.response?.data['error'] ==
              'You have already reported this property') {
        throw AlreadyReportedException(
            'You have already reported this property');
      }
      throw Exception('Failed to submit report: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  Future<Listing> updateProperty(Listing listing,
      {List<File> images = const [],
      List<File> floorPlanImages = const [],
      List<String> deletedImageUrls = const [],
      List<String> deletedFloorPlanUrls = const [],
      List<String> deletedDocumentUrls = const []}) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/properties/${listing.id}'),
      );

      request.headers.addAll(_headers);
      request.fields['listing'] = jsonEncode(listing.toJson());
      request.fields['deletedImageUrls'] = jsonEncode(deletedImageUrls);
      request.fields['deletedFloorPlanUrls'] = jsonEncode(deletedFloorPlanUrls);
      request.fields['deletedDocumentUrls'] = jsonEncode(deletedDocumentUrls);

      // Add new property images
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

      // Add new floor plan images
      for (var image in floorPlanImages) {
        final fileName = image.path.split('/').last;
        final stream = http.ByteStream(image.openRead());
        final length = await image.length();

        final multipartFile = http.MultipartFile(
          'floorPlanImages',
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
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to update property';
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
      throw Exception('Failed to update property: $e');
    }
  }

  Future<List<PropertyLead>> getPropertyLeads() async {
    try {
      final response = await _dio.get('/api/leads');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['leads'];
        return data.map((json) => PropertyLead.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load property leads');
      }
    } catch (e) {
      throw Exception('Failed to load property leads: $e');
    }
  }

  Future<void> trackPropertyView(int propertyId) async {
    try {
      final response = await _dio.post('/api/leads/$propertyId/view');

      if (response.statusCode != 200) {
        throw Exception('Failed to track property view');
      }
    } catch (e) {
      print('Failed to track property view: $e');
      // Silently fail as this shouldn't affect the user experience
    }
  }

  Future<Map<String, dynamic>> getLocationDetails(int propertyId) async {
    try {
      final response =
          await _dio.get('/api/properties/$propertyId/location-details');
      if (response.statusCode == 200) {
        return {
          'walkScore': response.data['walkScore'] ?? 0,
          'transitScore': response.data['transitScore'] ?? 0,
          'transitDetails': response.data['transitDetails'] ??
              {'railLines': [], 'busLines': []},
          'isRoomifyChoice': response.data['isRoomifyChoice'] ?? false,
          'floorPlans': response.data['floorPlans'] ?? [],
        };
      }
      throw Exception('Failed to fetch location details');
    } catch (e) {
      throw Exception('Failed to fetch location details: $e');
    }
  }

  Future<Listing> addFloorPlan(
    Listing listing, {
    required FloorPlan floorPlan,
    File? imageFile,
  }) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/properties/${listing.id}/floor-plans'),
      );
      request.headers.addAll(_headers);

      // Add floor plan data
      request.fields['floorPlan'] = jsonEncode(floorPlan.toJson());
      request.fields['listing'] = jsonEncode(listing.toJson());

      // Add image if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: fileName,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Listing.fromJson(json.decode(response.body)['listing']);
      } else {
        throw Exception('Failed to add floor plan');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Listing> updateFloorPlan(
    int listingId,
    String floorPlanId,
    Map<String, dynamic> floorPlanData, {
    File? imageFile,
  }) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Convert squareFeet to squareFootage if it exists
      if (floorPlanData.containsKey('squareFeet')) {
        floorPlanData['squareFootage'] = floorPlanData.remove('squareFeet');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            '$baseUrl/api/properties/$listingId/floor-plans/$floorPlanId'),
      );
      request.headers.addAll(_headers);

      // Add floor plan data
      request.fields['floorPlanData'] = jsonEncode(floorPlanData);

      // Add image if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: fileName,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Listing.fromJson(json.decode(response.body)['listing']);
      } else {
        throw Exception('Failed to update floor plan');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Listing> deleteFloorPlan(int listingId, String floorPlanId) async {
    try {
      final response = await _dio.delete(
        '/api/properties/$listingId/floor-plans/$floorPlanId',
      );

      if (response.statusCode == 200) {
        return Listing.fromJson(response.data['listing']);
      } else {
        throw Exception('Failed to delete floor plan');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Listing?> getPropertyById(String propertyId) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await http
          .get(Uri.parse('$baseUrl/api/properties/$propertyId'), headers: {
        'Authorization': 'Bearer $token',
      });
      print('Response: ${response.request?.url}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Listing.fromJson(data['listing']);
      }
      return null;
    } catch (e) {
      print('Error fetching property: $e');
      return null;
    }
  }
}

class AlreadyReportedException implements Exception {
  final String message;
  AlreadyReportedException(this.message);

  @override
  String toString() => message;
}
