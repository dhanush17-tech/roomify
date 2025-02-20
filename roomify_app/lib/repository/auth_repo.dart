import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/utils.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String REMEMBER_ME_TOKEN_KEY = 'auth_token';
  static const String SESSION_TOKEN_KEY = 'session_token';

  AuthRepository() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Add token to header
            final token = await getTokenOrThrow();
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-Custom-Auth-Key'] = 'roomify-secret';
            return handler.next(options);
          } catch (e) {
            // If there's an error getting the token, return 401
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  statusMessage: 'Unauthorized',
                ),
                type: DioExceptionType.badResponse,
                error: 'Authentication required',
              ),
            );
          }
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Clear tokens on unauthorized response
            await deleteToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'X-Custom-Auth-Key': 'roomify-secret',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token == null || token.isEmpty) {
          throw Exception('Invalid token received from server');
        }

        // Save token using the saveToken method
        await saveToken(token, isSession: !rememberMe);

        final userProfile = await getUserProfile(token);
        return User.fromJson(userProfile);
      } else {
        final errorData = jsonDecode(response.body);
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

  Future<User> signInAnonymously() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/anonymous'),
        headers: {
          'Content-Type': 'application/json',
          'X-Custom-Auth-Key': 'roomify-secret',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token == null || token.isEmpty) {
          throw Exception('Invalid token received from server');
        }

        // Save token as a session token (temporary)
        await saveToken(token, isSession: true);

        final userProfile = await getUserProfile(token);
        return User.fromJson(userProfile)..isAnonymous = true;
      } else {
        throw Exception('Failed to sign in anonymously');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error. Please check your connection');
    }
  }

  Future<User> register({
    required String displayName,
    required String email,
    required String password,
    int? age,
    String? university,
    String? location,
    required bool isProfessional,
    String? phoneNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'displayName': displayName,
          'email': email,
          'password': password,
          'age': age,
          'university': university,
          'location': location,
          'isProfessional': isProfessional,
          'phoneNumber': phoneNumber,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await saveToken(token);
        return User.fromJson(data['user']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']);
      }
    } catch (e) {
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      final token = await getToken();
      if (token == null) return;
      //print the post url
      print('Post URL: ${_dio.options.baseUrl}/signout');
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
          'X-Custom-Auth-Key': 'roomify-secret',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Clear tokens if unauthorized
        await deleteToken();
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Failed to get profile');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
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
    double? latitude,
    double? longitude,
    String? location,
    String? status,
    File? profileImage,
    String? phoneNumber,
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
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (status != null) 'status': status!,
        if (location != null) 'location': location!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
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

  Future<String?> getToken() async {
    try {
      // Try to get session token first
      String? token = await _secureStorage.read(key: SESSION_TOKEN_KEY);

      // If no session token, try to get remember me token
      if (token == null) {
        token = await _secureStorage.read(key: REMEMBER_ME_TOKEN_KEY);
      }

      return token;
    } catch (e) {
      return null;
    }
  }

  Future<String> getTokenOrThrow() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required. Please log in again.');
    }
    return token;
  }

  Future<void> saveToken(String token, {bool isSession = false}) async {
    try {
      final key = isSession ? SESSION_TOKEN_KEY : REMEMBER_ME_TOKEN_KEY;

      // Delete any existing tokens first
      await deleteToken();

      // Save the new token
      await _secureStorage.write(
        key: key,
        value: token,
      );
    } catch (e) {
      throw Exception('Failed to save authentication token');
    }
  }

  Future<void> deleteToken() async {
    // Clear both types of tokens
    await _secureStorage.delete(key: REMEMBER_ME_TOKEN_KEY);
    await _secureStorage.delete(key: SESSION_TOKEN_KEY);
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
