import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/repository/profile_repo.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roomify_app/utils.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileUpdateRepo _repository;
  final BuildContext context;

  ProfileProvider(this._repository, this.context) {
    _initializeLocation();
  }

  bool _isLoading = false;
  String? _error;
  List<String> _interests = [];
  List<String> _preferences = [];
  Map<String, String> _socialLinks = {};
  List<Listing> _properties = [];
  List<Listing> _marketplaceItems = [];

  List<String> get interests => _interests;
  List<String> get preferences => _preferences;
  Map<String, String> get socialLinks => _socialLinks;
  List<Listing> get properties => _properties;
  List<Listing> get marketplaceItems => _marketplaceItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get latitude => _latitude;
  double get longitude => _longitude;

  String? _currentLocation;
  double _latitude = 0.0;
  double _longitude = 0.0;

  String? get currentLocation => _currentLocation;

  Future<void> _initializeLocation() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;

      // If user has saved location, use that
      if (user != null && user.latitude != null && user.longitude != null) {
        _latitude = user.latitude!;
        _longitude = user.longitude!;
        _currentLocation = await _getLocationName(_latitude, _longitude);
        notifyListeners();
        return;
      }

      // Otherwise request current location
      final position = await _getCurrentLocation();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation = await _getLocationName(_latitude, _longitude);

        // Update user location in backend
        await updateLocation(_latitude, _longitude);
      }
    } catch (e) {
      _error = 'Failed to get location: ${e.toString()}';
      // Set default location (e.g., city center)
      _latitude = 40.7128; // New York coordinates as fallback
      _longitude = -74.0060;
    } finally {
      notifyListeners();
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Handle permanent denial
        await openAppSettings();
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$mapboxToken'),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timed out'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          return data['features'][0]['place_name'];
        }
      }
      throw Exception('Failed to get location name');
    } catch (e) {
      _error = e.toString();
      return 'Unknown Location';
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.updateUserLocation(latitude, longitude);
      _latitude = latitude;
      _longitude = longitude;
      _currentLocation = await _getLocationName(latitude, longitude);

      // Update AuthProvider user data
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final updatedUser = authProvider.user!.copyWith(
          latitude: latitude,
          longitude: longitude,
        );
        authProvider.updateUser(updatedUser);
      }

      // Refresh all providers when location changes
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context);

    } catch (e) {
      _error = 'Failed to update location: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePreferences({
    required List<String> interests,
    required List<String> preferences,
    required Map<String, String> socialLinks,
  }) async {
    try {
      final updatedUser = await _repository.updatePreferences(
        interests: interests,
        preferences: preferences,
        socialLinks: socialLinks,
      );

      Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadUserListings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final listings = await _repository.getUserListings();

      _properties =
          listings.where((item) => item.type == ListingType.Property).toList();
      _marketplaceItems = listings
          .where((item) => item.type == ListingType.Marketplace)
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteListing(int listingId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.deleteListing(listingId);

      // Remove listing from local state
      _properties.removeWhere((item) => item.id == listingId);
      _marketplaceItems.removeWhere((item) => item.id == listingId);

      // Refresh all providers
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
