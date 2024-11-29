import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/utils.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to header
          final token = await getToken();
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['X-Custom-Auth-Key'] = 'roomify-secret';
          return handler.next(options);
        },
        onError: (error, handler) {
          print('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await saveToken(token);
        final userProfile = await getUserProfile(token);
        return User.fromJson(userProfile);
      } else {
        final errorData = jsonDecode(response.body);
        // Handle specific error cases
        switch (response.statusCode) {
          case 401:
            throw Exception('Invalid email or password');
          case 404:
            throw Exception('Account not found');
          case 403:
            throw Exception('Account is locked. Please contact support');
          default:
            throw Exception(errorData['error'] ?? 'Login failed');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection');
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String displayName,
    int? age,
    String? university,
    String? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
          'age': age, // Optional
          'university': university, // Optional
          'location': location, // Optional
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        // Save token to secure storage
        await saveToken(token);

        final userProfile = await getUserProfile(token);
        return User.fromJson(userProfile);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final token = await getToken();
      if (token == null) return;

      // Blacklist token on server
      await _dio.post('/signout');

      // Clear local storage
      deleteToken();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get profile');
      }
    } catch (e) {
      throw Exception('Failed to get profile: $e');
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
    String? status,
    File? profileImage,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        if (displayName != null) 'displayName': displayName!,
        if (email != null) 'email': email!,
        if (password != null) 'password': password!,
        if (university != null) 'university': university!,
        if (bio != null) 'bio': bio!,
        if (age != null) 'age': age.toString(),
        if (gender != null) 'gender': gender!,
        if (status != null) 'status': status!,
        if (profileImage != null)
          'profilePhoto': await MultipartFile.fromFile(profileImage.path,
              filename: "${userId}")
      });

      final response = await _dio.put(
        '/api/user/profile',
        data: formData,
      );

      if (response.statusCode == 200) {
        // If password was updated, re-login
        if (password != null) {
          return await login(
            email: email ?? response.data['email'],
            password: password,
          );
        }

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

  // Delete profile photo
  Future<User> deleteProfilePhoto() async {
    try {
      final response = await _dio.delete('/api/user/profile/profile-photo');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to delete profile photo');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<String> getToken() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No token found');
    }
    return token;
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Failed to send reset link: $e');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/password-reset/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }
}
