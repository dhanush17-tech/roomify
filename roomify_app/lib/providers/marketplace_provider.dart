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
  String _error = '';
  Timer? _debounceTimer;
  double? _minPrice;
  double? _maxPrice;
  bool _disposed = false;

  MarketplaceProvider(this._repository, this.context) {
    Future.microtask(() => loadItems());
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  List<Listing> get items => _items;
  List<Listing> get searchSuggestions => _searchSuggestions;
  bool get isLoading => _isLoading;
  String get error => _error;

  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    loadItems();
  }

  Future<void> loadItems() async {
    if (_disposed) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      _items = await _repository.getMarketplaceItems(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      _error = '';
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
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
    if (_disposed) return;

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

      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw e;
    }
  }

  Future<void> search(String query) async {
    if (_disposed) return;

    try {
      _isLoading = true;
      notifyListeners();

      _items = await _repository.searchMarketplaceItems(query);

      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> getSearchSuggestions(String query) async {
    if (_disposed) return;

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
      if (_disposed) return;

      try {
        _searchSuggestions = await _repository.getSearchSuggestions(query);
        if (!_disposed) {
          notifyListeners();
        }
      } catch (e) {
        _error = e.toString();
        if (!_disposed) {
          notifyListeners();
        }
      }
    });
  }

  void clearSearchSuggestions() {
    if (_disposed) return;
    _searchSuggestions = [];
    notifyListeners();
  }

  void clearItems() {
    if (_disposed) return;
    _items = [];
    _searchSuggestions = [];
    _error = '';
    notifyListeners();
  }

  Future<void> refreshItems() async {
    if (_disposed) return;
    await loadItems();
  }

  Future<void> updateMarketplaceItem({
    required int id,
    required String title,
    required String description,
    required double price,
    required String location,
    required double latitude,
    required double longitude,
    required List<String> categories,
    required List<File> images,
    List<String>? existingImageUrls,
  }) async {
    if (_disposed) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _repository.updateMarketplaceItem(
        id: id,
        title: title,
        description: description,
        price: price,
        location: location,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
        images: images,
        existingImageUrls: existingImageUrls ?? [],
      );

      await loadItems(); // Refresh items list
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw e;
    }
  }
}
