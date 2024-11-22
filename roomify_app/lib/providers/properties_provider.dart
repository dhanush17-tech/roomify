import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/repository/properties_repo.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  bool _isLoading = false;
  String? _error;
  List<Property> _recommendations = [];
  double _latitude = 0.0;
  double _longitude = 0.0;
  List<Property> _pairUpListings = [];

  double get latitude => _latitude;
  double get longitude => _longitude;
  List<Property> get pairUpListings => _pairUpListings;

  void setCoordinates(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
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

  PropertyProvider(this._repository) {
    initializeLocation();
    fetchPairUpListings();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Property> get recommendations => _recommendations;

  Future<void> createProperty(Property property, List<File> images) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.createProperty(property, images);
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
}
