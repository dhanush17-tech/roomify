import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/search_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  BuildContext context;

  AuthProvider(this._authRepository, this.context);

  User? _user;
  bool _isLoading = false;
  String? _error;

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

  Future<void> login(String email, String password, Function onSuccess) async {
    try {
      _setLoading(true);
      _setError(null);

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields');
      }

      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      _setUser(user);
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
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      await _authRepository.deleteToken();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
      {required String email,
      required String password,
      required String displayName,
      required int age,
      required String university,
      required String location,
      required Function onSuccess}) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = await _authRepository.register(
          displayName: displayName,
          email: email,
          password: password,
          age: age,
          university: university,
          location: location);

      _setUser(user);
      onSuccess();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? status,
    String? displayName,
    String? email,
    String? password,
    String? university,
    String? bio,
    int? age,
    String? gender,
    File? profileImage,
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
          gender: gender,
          profileImage: profileImage);

      _user = updatedUser;

      // Refresh all providers
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

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _user = null;
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

  Future<void> resetPassword(
      String? token, String password, Function onSuccess) async {
    try {
      _isLoading = true;
      notifyListeners();
      if (token != null) {
        await _authRepository.resetPassword(token: token, password: password);
        onSuccess;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading;
      notifyListeners();
    }
  }

  Future<void> refreshAllProviders(BuildContext context) async {
    try {
      // Refresh user profile
      await loadUserProfile();

      // Refresh PropertyProvider
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      await propertyProvider.fetchRecommendations();
      await propertyProvider.loadFavorites();
      await propertyProvider.fetchPairUpListings();

      // Refresh MarketplaceProvider
      final marketplaceProvider = Provider.of<MarketplaceProvider>(context, listen: false);
      await marketplaceProvider.loadItems();

      // Refresh ProfileProvider
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadUserListings();

      // Refresh SearchProvider
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      await searchProvider.fetchRecommendations();

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
