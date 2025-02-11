import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';
import 'package:http/http.dart' as http;

class ProfileUpdateRepo {
  final Dio _dio;
  ProfileUpdateRepo() : _dio = Dio() {
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

  Future<User> updatePreferences({
    required List<String> preferences,
  }) async {
    try {
      final response = await _dio.put(
        '/api/user/preferences',
        data: {'preferences': preferences, 'socialLinks': {}},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update preferences');
      }

      print('Preferences update response: ${response.data}');
      return User.fromJson(response.data);
    } catch (e) {
      print('Preferences update error: $e');
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<List<Listing>> getUserListings([String? userId]) async {
    try {
      const endpoint = '/api/user/profile/listings';

      final response = await _dio.get(endpoint,
          queryParameters: userId != null ? {'userId': userId} : null);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['listings'];
        return data.map((item) => Listing.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load user listings');
      }
    } catch (e) {
      throw Exception('Failed to load user listings: $e');
    }
  }

  Future<void> deleteListing(int listingId) async {
    try {
      final response = await _dio.delete(
        '/api/user/profile/listings/$listingId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete listing');
      }
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  Future<void> updateUserLocation(double latitude, double longitude) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/profile/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  Future<void> updateFcmToken(String token) async {
    final response = await _dio.put('/api/user/profile/fcm-token', data: {
      'fcmToken': token,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to update FCM token');
    }

    return response.data;
  }

  Future<void> deleteAccount() async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.delete(
        '$baseUrl/api/user/profile/delete-account',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<User> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? password,
    String? university,
    String? bio,
    int? age,
    String? gender,
    String? location,
    String? status,
    String? phoneNumber,
    File? profileImage,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        if (displayName != null) 'displayName': displayName,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        if (university != null) 'university': university,
        if (bio != null) 'bio': bio,
        if (age != null) 'age': age.toString(),
        if (gender != null) 'gender': gender,
        if (status != null) 'status': status,
        if (location != null) 'location': location,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profileImage != null)
          'profilePhoto': await MultipartFile.fromFile(profileImage.path,
              filename: "${userId}")
      });

      final response = await _dio.put(
        '/api/user/profile',
        data: formData,
      );

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to update profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
