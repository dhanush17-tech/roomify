import 'package:flutter/material.dart';
import 'package:roomify_app/models/filterModel.dart';
import 'package:roomify_app/repository/search_repo.dart';

class SearchProvider extends ChangeNotifier {
  final SearchRepository _repository;
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  FilterOptions? _filterOptions;
  String _activeTab = 'Property'; // 'Property', 'Roommate', 'Marketplace'

  SearchProvider(this._repository);

  List<dynamic> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get activeTab => _activeTab;
  FilterOptions? get filterOptions => _filterOptions;

  Future<void> search(String query) async {
    try {
      _isLoading = true;
      _searchQuery = query;
      notifyListeners();

      _searchResults = await _repository.search(
        query: query,
        type: _activeTab,
        filterOptions: _filterOptions,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
    notifyListeners();
  }

  void setFilterOptions(FilterOptions options) {
    _filterOptions = options;
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
    notifyListeners();
  }
}
