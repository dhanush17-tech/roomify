import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(
    this._authRepository,
  );

  User? _user;
  bool _isLoading = false;
  String? _error;
  double _latitude = 0.0;
  double _longitude = 0.0;

  double get latitude => _latitude;
  double get longitude => _longitude;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> login(
      BuildContext context, String email, String password, Function onSuccess,
      {bool rememberMe = true}) async {
    try {
      _setLoading(true);
      _setError(null);

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields');
      }

      final user = await _authRepository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      _setUser(user);
      await refreshAllProviders(context);
      onSuccess();
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  void updateUser(User newUser) {
    _user = newUser;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    try {
      _setLoading(true);
      final token = await _authRepository.getToken();
      if (token == null) throw Exception('No token found');

      final userProfile = await _authRepository.getUserProfile(token);
      _user = User.fromJson(userProfile);
      _latitude = _user!.latitude ?? 0.0;
      _longitude = _user!.longitude ?? 0.0;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      await _authRepository.deleteToken();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required BuildContext context,
    required String email,
    required String password,
    required String displayName,
    int? age,
    String? university,
    String? location,
    required bool isProfessional,
    required Function onSuccess,
    double? latitude,
    double? longitude,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = await _authRepository.register(
        displayName: displayName,
        email: email,
        password: password,
        age: isProfessional ? null : age,
        university: isProfessional ? null : university,
        location: isProfessional ? null : location,
        isProfessional: isProfessional,
        latitude: latitude,
        phoneNumber: phoneNumber,
        longitude: longitude,
      );

      _setUser(user);
      await refreshAllProviders(context);
      onSuccess();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    required BuildContext context,
    String? status,
    String? displayName,
    String? email,
    String? password,
    String? university,
    String? bio,
    int? age,
    String? gender,
    String? location,
    File? profileImage,
    String? phoneNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedUser = await _authRepository.updateProfile(
          userId: _user!.id,
          displayName: displayName,
          status: status,
          email: email,
          password: password,
          university: university,
          bio: bio,
          age: age,
          location: location,
          gender: gender,
          latitude: latitude,
          longitude: longitude,
          phoneNumber: phoneNumber,
          profileImage: profileImage);

      _user = updatedUser;
      await refreshAllProviders(context);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfilePhoto() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authRepository.deleteProfilePhoto();

      _user = _user!.copyWith(profilePhotoUrl: null);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _authRepository.signOut();
      _user = null;
      final marketplaceProvider =
          Provider.of<MarketplaceProvider>(context, listen: false);
      marketplaceProvider.clearItems();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> requestPassswordReset(String email, Function onSent) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authRepository.requestPasswordReset(email: email);
      onSent;
    } catch (e) {
      print(e.toString());
      _error = "Email Failed";
    } finally {
      _isLoading = false;
      _error = "";
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _authRepository.resetPassword(
        token: token,
        password: newPassword,
      );
    } catch (e) {
      throw Exception('Failed to reset password: ${e.toString()}');
    }
  }

  Future<void> refreshAllProviders(BuildContext context) async {
    try {
      // Refresh user profile
      await loadUserProfile();

      // Use Provider.of with a try-catch to handle potential provider not found errors
      try {
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        await propertyProvider.fetchRecommendations(_latitude, _longitude);
        await propertyProvider.loadFavorites();

        await propertyProvider.fetchPairUpListings();
      } catch (e) {
        print('PropertyProvider not available: $e');
      }

      try {
        final marketplaceProvider =
            Provider.of<MarketplaceProvider>(context, listen: false);
        await marketplaceProvider.loadItems();
      } catch (e) {
        print('MarketplaceProvider not available: $e');
      }

      try {
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.loadUserListings();
      } catch (e) {
        print('ProfileProvider not available: $e');
      }

      
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
