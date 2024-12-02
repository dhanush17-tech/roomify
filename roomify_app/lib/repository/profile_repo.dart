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
    required Map<String, String> socialLinks,
  }) async {
    try {
      final response = await _dio.put(
        '/api/user/preferences',
        data: {
          'preferences': preferences,
          'socialLinks': socialLinks,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update preferences');
      }
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<List<Listing>> getUserListings() async {
    try {
      final response = await _dio.get(
        '/api/user/profile/listings',
      );

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
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = await http.put(
        Uri.parse('$baseUrl/api/user/profile/location'),
        headers: _headers,
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }
}
