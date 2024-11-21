import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/repository/properties_repo.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyRepository _repository;
  bool _isLoading = false;
  String? _error;

  PropertyProvider(this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

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
}
