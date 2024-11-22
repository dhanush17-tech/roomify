import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';

class UserProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserProvider(this._authRepository);

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
    notifyListeners();
  }

  void _setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      _setUser(user);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
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
      required String location}) async {
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
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
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
          email: email,
          password: password,
          university: university,
          bio: bio,
          age: age,
          gender: gender,
          profileImage: profileImage);

      _user = updatedUser;
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

      _user = _user!.copyWith(profileImageUrl: null);
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
}
