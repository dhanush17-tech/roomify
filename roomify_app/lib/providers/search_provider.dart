import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/suggestion.dart' as models;
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/repository/properties_repo.dart';
import 'package:roomify_app/repository/search_repo.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:roomify_app/utils.dart';

class SearchProvider with ChangeNotifier {
  final SearchRepository _repository;
  final BuildContext context;

  List<Listing> _searchResults = [];
  List<Listing> _originalProperties = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _activeTab = 'Property';
  FilterOptions? _currentFilters;
  bool _noResults = false;
  double? _searchLat;
  double? _searchLng;
  String? _selectedLocation;
  String? _error;
  List<models.LocationSuggestion> _locationSuggestions = [];
  List<models.PropertySuggestion> _propertySuggestions = [];

  SearchProvider(this._repository, this.context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    fetchRecommendations(authProvider.latitude, authProvider.longitude);
  }

  List<Listing> get searchResults => _searchResults;
  List<Listing> get originalProperties => _originalProperties;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;
  FilterOptions? get currentFilters => _currentFilters;
  bool get noResults => _noResults;
  String? get selectedLocation => _selectedLocation;
  double? get searchLat => _searchLat;
  double? get searchLng => _searchLng;
  bool get hasSuggestions =>
      _locationSuggestions.isNotEmpty || _propertySuggestions.isNotEmpty;
  String? get error => _error;
  List<models.LocationSuggestion> get locationSuggestions =>
      _locationSuggestions;
  List<models.PropertySuggestion> get propertySuggestions =>
      _propertySuggestions;

  set searchResults(List<Listing> results) {
    _searchResults = results;
    notifyListeners();
  }

  Future<void> search(String query,
      {double? searchLat,
      double? searchLng,
      FilterOptions? filterOptions}) async {
    if (query.isEmpty && filterOptions == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _repository.search(
        query: query,
        type: 'Property',
        searchLatitude: _searchLat,
        searchLongitude: _searchLng,
        filterOptions: filterOptions,
      );
      _searchResults = results;
      _originalProperties = List.from(results);
    } catch (e) {
      print('Error searching: $e');
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSuggestions(String query) async {
    if (query.isEmpty) {
      clearSuggestions();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () async {
      try {
        final suggestions = await _repository.getSuggestions(query);

        if (suggestions['locations'] != null) {
          _locationSuggestions = (suggestions['locations'] as List)
              .map((location) => models.LocationSuggestion(
                    id: location['id'] as String,
                    name: location['name'] as String,
                    fullName: location['full_name'] as String,
                    type: location['type'] as String,
                    coordinates: List<double>.from(location['coordinates']),
                    context: location['context'] as String?,
                  ))
              .toList();
        }

        if (suggestions['properties'] != null) {
          _propertySuggestions = (suggestions['properties'] as List)
              .map((property) => models.PropertySuggestion(
                    id: property['id'],
                    title: property['title'] as String,
                    location: property['location'] as String?,
                  ))
              .toList();
        }

        notifyListeners();
      } catch (e) {
        print('Error getting suggestions: $e');
        clearSuggestions();
      }
    });
  }

  void selectLocation(double lat, double lng, String locationName) {
    _searchLat = lat;
    _searchLng = lng;
    _selectedLocation = locationName;
    clearSuggestions();
    notifyListeners();
  }

  void clearSuggestions() {
    _locationSuggestions = [];
    _propertySuggestions = [];
    notifyListeners();
  }

  Future<void> searchProperties({
    String? query,
    FilterOptions? filterOptions,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _repository.search(
        query: query,
        searchLatitude: _searchLat,
        searchLongitude: _searchLng,
        filterOptions: filterOptions,
      );
      _searchResults = results;
      _originalProperties = List.from(results);
      notifyListeners();
    } catch (e) {
      print('Error searching properties: $e');
      _searchResults = [];
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _selectedLocation = null;
    _searchLat = null;
    _searchLng = null;
    clearSuggestions();
  }

  // Helper methods for initial load and recommendations
  Future<void> fetchRecommendations(double latitude, double longitude) async {
    _searchQuery = '';
    await loadInitialProperties(latitude, longitude);
  }

  Future<void> loadInitialProperties(double latitude, double longitude) async {
    try {
      _isLoading = true;
      _noResults = false;
      notifyListeners();

      final properties =
          await _repository.getRecommendedProperties(latitude, longitude);
      _searchResults = properties;
      _originalProperties = List.from(properties);

      _noResults = _searchResults.isEmpty;
    } catch (e) {
      print('Error loading initial properties: $e');
      _noResults = true;
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    search('',
        searchLat: profileProvider.latitude,
        searchLng: profileProvider.longitude);
    notifyListeners();
  }
}
