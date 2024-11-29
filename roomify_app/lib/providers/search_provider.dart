import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/repository/search_repo.dart';

class SearchProvider extends ChangeNotifier {
  final SearchRepository _repository;
  final BuildContext context;
  List<Listing> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
   String _activeTab = 'Property'; // 'Property', 'Roommate', 'Marketplace'
  FilterOptions? _currentFilters;
  bool _noResults = false;

  SearchProvider(this._repository, this.context) {
    fetchRecommendations();
  }

  List<Listing> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;
  FilterOptions? get currentFilters => _currentFilters;
  bool get noResults => _noResults;

  Future<void> search(String query) async {
    _searchQuery = query;
    await _performSearch();
  }

  Future<void> fetchRecommendations() async {
    _searchQuery = '';
    await _performSearch();
  }

  void setFilterOptions(FilterOptions filters) {
    _currentFilters = filters;
    notifyListeners();
  }

  void clearFilters() {
    _currentFilters = null;
    notifyListeners();
  }

  Future<void> _performSearch() async {
    try {
      _isLoading = true;
      _noResults = false;
      notifyListeners();

      final user = Provider.of<AuthProvider>(context, listen: false).user;

      _searchResults = await _repository.search(
        query: _searchQuery,
        type: _activeTab,
        filterOptions: _currentFilters,
        userLat: user?.latitude,
        userLng: user?.longitude,
        radius: 10.0,
      );

      _noResults = _searchResults.isEmpty;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _noResults = true;
      notifyListeners();
      print('Search error: $e');
    }
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    _performSearch();
    notifyListeners();
  }
}
