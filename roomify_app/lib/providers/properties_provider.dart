import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/repository/properties_repo.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  final BuildContext context;
  bool _isLoading = false;
  String? _error;
  List<Listing> _recommendations = [];
  double _latitude = 0.0;
  double _longitude = 0.0;
  List<Listing> _pairUpListings = [];
  List<Listing> _favorites = [];

  double get latitude => _latitude;
  double get longitude => _longitude;
  List<Listing> get pairUpListings => _pairUpListings;

  List<Listing> get favorites => _favorites;

  void setCoordinates(double latitude, double longitude) async {
    _latitude = latitude;
    _longitude = longitude;
    
    await Provider.of<AuthProvider>(context, listen: false)
        .refreshAllProviders(context);
    
    notifyListeners();
  }

  Future<void> initializeLocation() async {
    try {
      final position = await _repository.determinePosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      notifyListeners();
      await fetchRecommendations();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize location: $e';
      notifyListeners();
    }
  }

  PropertyProvider(this._repository, this.context) {
    initializeLocation();
    fetchPairUpListings();
    loadFavorites();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Listing> get recommendations => _recommendations;

  Future<void> createProperty(Listing property, List<File> images) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.createProperty(property, images);

      // Refresh all providers
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context);

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recommendations = await _repository.getRecommendedListings(
          this._latitude, this.longitude);

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
      _isLoading = false;
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
}
