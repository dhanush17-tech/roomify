import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/services/api_service.dart';

class PropertyProvider extends ChangeNotifier {
  final ApiService _api;

  PropertyProvider(this._api);

  Future<PropertyOffer> addOffer({
    required int listingId,
    required String title,
    required String description,
    required DateTime validUntil,
  }) async {
    try {
      final response = await _api.post(
        '/property/$listingId/offers',
        body: jsonEncode({
          'title': title,
          'description': description,
          'validUntil': validUntil.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PropertyOffer.fromJson(data['offer']);
      } else {
        throw Exception('Failed to add offer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add offer: $e');
    }
  }

  Future<void> deleteOffer({
    required int listingId,
    required String offerId,
  }) async {
    try {
      final response = await _api.delete(
        '/property/$listingId/offers/$offerId',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete offer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete offer: $e');
    }
  }
}
