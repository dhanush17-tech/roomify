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
import 'package:roomify_app/views/auth/login.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileUpdateRepo _repository;
  final BuildContext context;

  ProfileProvider(this._repository, this.context) {
    _initializeLocation(context);
  }

  bool _isLoading = false;
  String? _error;
  List<String> _preferences = [];
  Map<String, String> _socialLinks = {};
  List<Listing> _properties = [];
  List<Listing> _marketplaceItems = [];

  List<String> get preferences => _preferences;
  Map<String, String> get socialLinks => _socialLinks;
  List<Listing> get properties => _properties;
  List<Listing> get marketplaceItems => _marketplaceItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double? get latitude => _latitude;
  double? get longitude => _longitude;

  String? _currentLocation;
  double? _latitude;
  double? _longitude;

  String? get currentLocation => _currentLocation;

  // Cache for other users' listings
  final Map<String, List<Listing>> _otherUsersListings = {};

  Future<void> _initializeLocation(BuildContext context) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;

      // If user has saved location, use that
      if (user != null && user.latitude != null && user.longitude != null) {
        _latitude = user.latitude!;
        _longitude = user.longitude!;
        _currentLocation = await _getLocationName(
          _latitude!, _longitude!);
        notifyListeners();
        return;
      }

      // Otherwise request current location
      final position = await _getCurrentLocation();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocation = await _getLocationName(_latitude!, _longitude!);

        // Update user location in backend
        await updateLocation(_latitude!, _longitude!, context);
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
      final url =
          "https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$mapboxToken";
      final response = await http
          .get(
            Uri.parse(url),
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

  Future<void> updateLocation(
      double latitude, double longitude, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update coordinates
      _latitude = latitude;
      _longitude = longitude;

      // Get address from coordinates
      final address = await getAddressFromCoordinates(latitude, longitude);
      _currentLocation = address;

      // Update in backend
      await _repository.updateUserLocation(latitude, longitude);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update location: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$mapboxToken',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final placeName = feature['place_name'] as String;

          // Extract just the city and state
          final parts = placeName.split(', ');
          if (parts.length >= 2) {
            return '${parts[parts.length - 3]}, ${parts[parts.length - 2]}';
          }
          return placeName;
        }
      }
      return 'Unknown Location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Unknown Location';
    }
  }

  Future<void> updatePreferences({
    required List<String> preferences,
  }) async {
    try {
      final updatedUser = await _repository.updatePreferences(
        preferences: preferences,
      );

      Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Listing>> loadUserListings([String? userId]) async {
    try {
      _isLoading = true;
      notifyListeners();

      // If requesting other user's listings, check cache first
      if (userId != null && _otherUsersListings.containsKey(userId)) {
        return _otherUsersListings[userId]!;
      }

      final listings = await _repository.getUserListings(userId);

      // If it's current user, update the local state
      if (userId == null) {
        _properties = listings
            .where((item) => item.type == ListingType.Property)
            .toList();
        _marketplaceItems = listings
            .where((item) => item.type == ListingType.Marketplace)
            .toList();
      }
      // If it's another user, cache their listings
      else {
        _otherUsersListings[userId] = listings;
      }

      _isLoading = false;
      notifyListeners();

      return listings;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Helper method to get cached listings synchronously
  List<Listing> getCachedListings([String? userId]) {
    if (userId == null) {
      return [..._properties, ..._marketplaceItems];
    }
    return _otherUsersListings[userId] ?? [];
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
      Future.microtask(() => Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFcmToken(String token) async {
    await _repository.updateFcmToken(token);
  }

  Future<void> updateUserLocation(double latitude, double longitude) async {
    try {
      await _repository.updateUserLocation(latitude, longitude);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await Future.microtask(() => authProvider.refreshAllProviders(context));
      notifyListeners();
    } catch (e) {
      print('Error updating user location: $e');
      throw e;
    }
  }

  // Add method to update a specific listing in the state
  void updateListingInState(Listing updatedListing) {
    // Update in properties list
    final propertyIndex =
        _properties.indexWhere((listing) => listing.id == updatedListing.id);
    if (propertyIndex != -1) {
      _properties[propertyIndex] = updatedListing;
    }

    // Update in marketplace items list
    final marketplaceIndex = _marketplaceItems
        .indexWhere((listing) => listing.id == updatedListing.id);
    if (marketplaceIndex != -1) {
      _marketplaceItems[marketplaceIndex] = updatedListing;
    }

    // Update in other users' listings cache if present
    _otherUsersListings.forEach((userId, listings) {
      final index =
          listings.indexWhere((listing) => listing.id == updatedListing.id);
      if (index != -1) {
        listings[index] = updatedListing;
      }
    });

    notifyListeners();
  }

  // Add method to add a new listing to the state
  void addListingToState(Listing newListing) {
    _properties.add(newListing);
    notifyListeners();
  }

  // Add method to remove a listing from the state
  void removeListingFromState(int listingId) {
    _properties.removeWhere((listing) => listing.id == listingId);
    notifyListeners();
  }

  // Force refresh all listings
  Future<void> refreshListings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final listings = await _repository.getUserListings();

      _properties =
          listings.where((item) => item.type == ListingType.Property).toList();
      _marketplaceItems = listings
          .where((item) => item.type == ListingType.Marketplace)
          .toList();

      // Clear other users' cache to force refresh on next access
      _otherUsersListings.clear();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete account from backend
      await _repository.deleteAccount();

      // Only clear local data if backend deletion was successful
      if (context.mounted) {
        await Provider.of<AuthProvider>(context, listen: false)
            .signOut(context);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      throw Exception('Error deleting account');
    }
  }
}
