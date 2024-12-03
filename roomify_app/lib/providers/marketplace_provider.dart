import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/repository/marketplace_repo.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceRepository _repository;
  final BuildContext context;
  List<Listing> _items = [];
  List<Listing> _searchSuggestions = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;

  MarketplaceProvider(this._repository, this.context) {
    loadItems();
  }

  List<Listing> get items => _items;
  List<Listing> get searchSuggestions => _searchSuggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadItems() async {
    try {
      _isLoading = true;
      notifyListeners();

      _items = await _repository.getMarketplaceItems();
      print(items);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMarketplaceItem({
    required String title,
    required String description,
    required double price,
    required String location,
    required double latitude,
    required double longitude,
    required List<String> categories,
    required List<File> images,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.createMarketplaceItem(
        title: title,
        description: description,
        price: price,
        location: location,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
        images: images,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> search(String query) async {
    try {
      _isLoading = true;
      notifyListeners();

      _items = await _repository.searchMarketplaceItems(query);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSearchSuggestions(String query) async {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Only fetch suggestions if query is not empty
    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    // Debounce the API call
    _debounceTimer = Timer(Duration(milliseconds: 300), () async {
      try {
        _searchSuggestions = await _repository.getSearchSuggestions(query);
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    });
  }

  void clearSearchSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }
 
}
