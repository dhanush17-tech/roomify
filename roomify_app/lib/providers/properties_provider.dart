import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/repository/properties_repo.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  final BuildContext context;
  bool _isLoading = false;
  String? _error;
  List<Listing> _recommendations = [];
  List<PropertyLead> _leads = [];

  List<Listing> _pairUpListings = [];
  List<Listing> _favorites = [];

  List<Listing> get pairUpListings => _pairUpListings;
  List<PropertyLead> get leads => _leads;
  List<Listing> get favorites => _favorites;

  Map<int, Map<String, dynamic>> _locationDetailsCache = {};

  Future<void> loadLeads() async {
    try {
      _isLoading = true;
      notifyListeners();

      _leads = await _repository.getPropertyLeads();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  PropertyProvider(this._repository, this.context) {
    fetchPairUpListings();
    loadFavorites();
    fetchRecommendations(
        Provider.of<AuthProvider>(context, listen: false).user!.latitude!,
        Provider.of<AuthProvider>(context, listen: false).user!.longitude!);
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Listing> get recommendations => _recommendations;

  Future<Listing> createProperty(Listing property, List<File> images) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Make the API call and wait for response
      final createdProperty =
          await _repository.createProperty(property, images);

      // Only refresh providers if the API call was successful
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context);

      _isLoading = false;
      notifyListeners();

      // Return the created property to indicate success
      return createdProperty;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      // Re-throw the error to be handled by the UI
      throw e;
    }
  }

  Future<void> fetchRecommendations(
      final double latitude, final double longitude) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recommendations =
          await _repository.getRecommendedListings(latitude, longitude);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch recommendations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPairUpListings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pairUpListings = await _repository.getPairUpListings();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch pair-up listings: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    try {
      _isLoading = true;
      for (Listing favourites in _favorites) {
        await _repository.removeFavorite(favourites.id);
      }
      _favorites = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {}
  }

  Future<void> loadFavorites() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get favorites from repository
      _favorites = await _repository.getFavorites();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Listing listing) async {
    try {
      final isFavorite = _favorites.any((item) => item.id == listing.id);

      if (isFavorite) {
        // Remove from favorites
        await _repository.removeFavorite(listing.id);
        _favorites.removeWhere((item) => item.id == listing.id);
      } else {
        // Add to favorites
        await _repository.addFavorite(listing.id);
        _favorites.add(listing);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Optionally show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite: ${e.toString()}')),
      );
    }
  }

  bool isFavorite(int listingId) {
    return _favorites.any((item) => item.id == listingId);
  }

  Future<void> refreshFavorites() async {
    await loadFavorites();
  }

  Future<Listing> updateProperty(Listing listing, List<File> newImages) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Pass both the listing and new images to repository
      final updatedListing =
          await _repository.updateProperty(listing, newImages);

      // Update recommendations if the listing exists there
      final recommendationIndex =
          _recommendations.indexWhere((item) => item.id == listing.id);
      if (recommendationIndex != -1) {
        _recommendations[recommendationIndex] = updatedListing;
      }

      // Update pair-up listings if the listing exists there
      final pairUpIndex =
          _pairUpListings.indexWhere((item) => item.id == listing.id);
      if (pairUpIndex != -1) {
        _pairUpListings[pairUpIndex] = updatedListing;
      }

      // Update favorites if the listing exists there
      final favoriteIndex =
          _favorites.indexWhere((item) => item.id == listing.id);
      if (favoriteIndex != -1) {
        _favorites[favoriteIndex] = updatedListing;
      }

      // Refresh user's listings in profile
      await Provider.of<ProfileProvider>(context, listen: false)
          .loadUserListings();

      _isLoading = false;
      notifyListeners();

      // Return the updated listing
      return updatedListing;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> trackPropertyView(int propertyId) async {
    try {
      await _repository.trackPropertyView(propertyId);
    } catch (e) {
      // Silently fail as this shouldn't affect the user experience
      print('Failed to track property view: $e');
    }
  }

  Future<Map<String, dynamic>> getLocationDetails(int propertyId) async {
    try {
      // Check cache first
      if (_locationDetailsCache.containsKey(propertyId)) {
        return _locationDetailsCache[propertyId]!;
      }

      _isLoading = true;
      notifyListeners();

      final details = await _repository.getLocationDetails(propertyId);

      // Cache the results
      _locationDetailsCache[propertyId] = details;

      _isLoading = false;
      notifyListeners();

      return details;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
}
