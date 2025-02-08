import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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

  bool _isLoadingReccomendations = false;
  bool get isLoadingReccomendations => _isLoadingReccomendations;

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

  Future<Listing> createProperty(Listing listing,
      {List<File> images = const []}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final createdListing =
          await _repository.createProperty(listing, images: images);
      _updatePropertyInLists(createdListing);

      _isLoading = false;
      notifyListeners();
      return createdListing;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> fetchRecommendations(
      final double latitude, final double longitude) async {
    try {
      _isLoadingReccomendations = true;
      _error = null;
      notifyListeners();

      _recommendations =
          await _repository.getRecommendedProperties(latitude, longitude);

      _isLoadingReccomendations = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch recommendations: $e';
      _isLoadingReccomendations = false;
      notifyListeners();
    }
  }

  Future<void> fetchPairUpListings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pairUpListings = await _repository.getPairUpProperties();

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

      // Update optimistically
      if (isFavorite) {
        _favorites.removeWhere((item) => item.id == listing.id);
      } else {
        _favorites.add(listing.copyWith(isFavorite: true));
      }
      notifyListeners();

      // Make API call
      try {
        if (isFavorite) {
          await _repository.removeFavorite(listing.id);
        } else {
          await _repository.addFavorite(listing.id);
        }
      } catch (e) {
        // Revert on error
        if (isFavorite) {
          _favorites.add(listing);
        } else {
          _favorites.removeWhere((item) => item.id == listing.id);
        }
        notifyListeners();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in toggleFavorite: $e');
    }
  }

  bool isFavorite(int listingId) {
    return _favorites.any((item) => item.id == listingId);
  }

  Future<void> refreshFavorites() async {
    await loadFavorites();
  }

  Future<Listing> updateProperty(
    Listing listing, {
    List<File> images = const [],
    List<String> deletedImageUrls = const [],
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Pass both the listing and new images to repository
      final updatedListing = await _repository.updateProperty(
        listing,
        images: images,
        deletedImageUrls: deletedImageUrls,
      );

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
      _isLoading = true;
      notifyListeners();

      final details = await _repository.getLocationDetails(propertyId);

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

  Future<Listing> updateFloorPlan(
    int listingId,
    String floorPlanId,
    Map<String, dynamic> floorPlanData, {
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedListing = await _repository.updateFloorPlan(
        listingId,
        floorPlanId,
        floorPlanData,
        imageFile: imageFile,
      );

      // Update listing in all relevant lists
      _updatePropertyInLists(updatedListing);

      // Force refresh profile provider's listings
      await Provider.of<ProfileProvider>(context, listen: false)
          .refreshListings();

      _isLoading = false;
      notifyListeners();
      return updatedListing;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<Listing> addFloorPlan(
    Listing listing, {
    required FloorPlan floorPlan,
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedListing = await _repository.addFloorPlan(
        listing,
        floorPlan: floorPlan,
        imageFile: imageFile,
      );

      // Update listing in all relevant lists
      _updatePropertyInLists(updatedListing);

      // Force refresh profile provider's listings
      await Provider.of<ProfileProvider>(context, listen: false)
          .refreshListings();

      _isLoading = false;
      notifyListeners();
      return updatedListing;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<Listing> deleteFloorPlan(int listingId, String floorPlanId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedListing =
          await _repository.deleteFloorPlan(listingId, floorPlanId);

      // Update listing in all relevant lists
      _updatePropertyInLists(updatedListing);

      // Force refresh profile provider's listings
      await Provider.of<ProfileProvider>(context, listen: false)
          .refreshListings();

      _isLoading = false;
      notifyListeners();
      return updatedListing;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Helper method to update a property in all relevant lists
  void _updatePropertyInLists(Listing updatedListing) {
    // Update in recommendations if present
    final recommendationIndex =
        _recommendations.indexWhere((item) => item.id == updatedListing.id);
    if (recommendationIndex != -1) {
      _recommendations[recommendationIndex] = updatedListing;
    }

    // Update in pair-up listings if present
    final pairUpIndex =
        _pairUpListings.indexWhere((item) => item.id == updatedListing.id);
    if (pairUpIndex != -1) {
      _pairUpListings[pairUpIndex] = updatedListing;
    }

    // Update in favorites if present
    final favoriteIndex =
        _favorites.indexWhere((item) => item.id == updatedListing.id);
    if (favoriteIndex != -1) {
      _favorites[favoriteIndex] = updatedListing;
    }
  }

  Future<Listing?> getPropertyById(String propertyId) async {
    try {
      final listing = await _repository.getPropertyById(propertyId);
      return listing;
    } catch (e) {
      print('Error fetching property: $e');
      return null;
    }
  }
}
