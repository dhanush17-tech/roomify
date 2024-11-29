import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/repository/marketplace_repo.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';

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

  Future<void> createItem(Listing item, List<File> images) async {
    try {
      _isLoading = true;
      notifyListeners();

      final newItem = await _repository.createMarketplaceItem(item, images);
      _items.insert(0, newItem);

      // Refresh all providers
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
 