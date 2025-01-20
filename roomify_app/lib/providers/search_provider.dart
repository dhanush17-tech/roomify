import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/repository/search_repo.dart';
import 'dart:async';

class SearchProvider extends ChangeNotifier {
  final SearchRepository _repository;
  final BuildContext context;
  List<Listing> _searchResults = [];
  List<Listing> _searchSuggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _activeTab = 'Property';
  FilterOptions? _currentFilters;
  bool _noResults = false;

  SearchProvider(this._repository, this.context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    fetchRecommendations(authProvider.latitude, authProvider.longitude);
  }

  List<Listing> get searchResults => _searchResults;
  List<Listing> get searchSuggestions => _searchSuggestions;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;
  FilterOptions? get currentFilters => _currentFilters;
  bool get noResults => _noResults;

  Future<void> search(String query,
      {double? searchLat, double? searchLng}) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final latitude = searchLat ?? authProvider.latitude;
      final longitude = searchLng ?? authProvider.longitude;

      _searchResults = await _repository.search(
        query: query,
        type: 'Property',
        userLat: latitude,
        userLng: longitude,
      );
      print('Search results: ${_searchResults.length}');
    } catch (e) {
      _searchResults = [];
      print('Error searching: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRecommendations(double latitude, double longitude) async {
    _searchQuery = '';
    await loadInitialProperties(latitude, longitude);
  }

  Future<void> loadInitialProperties(double latitude, double longitude) async {
    try {
      _isLoading = true;
      _noResults = false;
      notifyListeners();

      _searchResults = await _repository.search(
        query: '',
        type: _activeTab,
        filterOptions: _currentFilters,
        userLat: latitude,
        userLng: longitude,
        radius: 10.0,
      );

      _noResults = _searchResults.isEmpty;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _noResults = true;
      notifyListeners();
      print('Error loading initial properties: $e');
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

  Future<void> getSearchSuggestions(String query,
      {double? searchLat, double? searchLng}) async {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 300), () async {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final latitude = searchLat ?? authProvider.latitude;
        final longitude = searchLng ?? authProvider.longitude;

        _searchSuggestions = await _repository.getSearchSuggestions(
          query,
          latitude: latitude,
          longitude: longitude,
        );
        notifyListeners();
      } catch (e) {
        _searchSuggestions = [];
        print('Error getting suggestions: $e');
        notifyListeners();
      }
    });
  }

  void clearSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }
}
