import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';

class MarketplaceRepository {
  Future<Listing> createMarketplaceItem(
      {required String title,
      required String description,
      required double price,
      required String location,
      required double latitude,
      required double longitude,
      required List<String> categories,
      required List<File> images}) async {
    try {
      final token = await AuthRepository().getToken();
      final headers = {
        'Authorization': 'Bearer $token',
      };

      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/marketplace'));
      request.headers.addAll(headers);

      // Create the listing object
      final listingData = {
        'title': title,
        'description': description,
        'price': price,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'categories': categories,
        'type': 'Marketplace'
      };

      // Add the listing data as a field
      request.fields['listing'] = jsonEncode(listingData);

      // Add all images
      for (var image in images) {
        final fileName = image.path.split('/').last;
        final stream = http.ByteStream(image.openRead());
        final length = await image.length();

        final multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: fileName,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData)['listing'];
        return Listing.fromJson(data);
      } else {
        throw Exception('Failed to create marketplace item');
      }
    } catch (e) {
      throw Exception('Failed to create marketplace item: $e');
    }
  }

  Future<List<Listing>> getMarketplaceItems(
      {double? minPrice, double? maxPrice}) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Build URL with query parameters
      var uri = Uri.parse('$baseUrl/api/marketplace');
      if (minPrice != null || maxPrice != null) {
        final queryParams = <String, String>{};
        if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
        if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['items'];
        final List<Listing> listings =
            data.map((item) => Listing.fromJson(item)).toList();
        return listings;
      } else {
        throw Exception('Failed to load marketplace items');
      }
    } catch (e) {
      throw Exception('Failed to load marketplace items: $e');
    }
  }

  Future<List<Listing>> searchMarketplaceItems(String query) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/marketplace/search?query=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['items'];
        return data.map((item) => Listing.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search marketplace items');
      }
    } catch (e) {
      throw Exception('Failed to search marketplace items: $e');
    }
  }

  Future<List<Listing>> getSearchSuggestions(String query) async {
    try {
      final token = await AuthRepository().getToken();
      final _headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/marketplace/suggestions?query=$query'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['items'] ?? [];
        final List<Listing> listings =
            data.map((item) => Listing.fromJson(item)).toList();
        return listings;
      } else {
        throw Exception('Failed to get search suggestions');
      }
    } catch (e) {
      throw Exception('Failed to get search suggestions: $e');
    }
  }
}
