import 'dart:io';
import 'package:flutter/material.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/repository/marketplace_repo.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceRepository _repository;
  final BuildContext context;
  List<Listing> _items = [];
  bool _isLoading = false;
  String? _error;

  MarketplaceProvider(this._repository, this.context) {
    loadItems();
  }

  List<Listing> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadItems() async {
    try {
      _isLoading = true;
      notifyListeners();

      _items = await _repository.getMarketplaceItems();

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

      final newItem = await _repository.createMarketplaceItem(
        title: title,
        description: description,
        price: price,
        location: location,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
        images: images,
      );

      _items.insert(0, newItem);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
}
