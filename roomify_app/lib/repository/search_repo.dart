import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roomify_app/models/filterModel.dart';

class SearchRepository {
  final String baseUrl = 'http://10.0.2.2:8787';

  Future<List<dynamic>> search({
    required String query,
    required String type,
    FilterOptions? filterOptions,
  }) async {
    try {
      final queryParams = {
        'query': query,
        'type': type,
        if (filterOptions?.gender != null) 'gender': filterOptions!.gender,
        if (filterOptions?.minPrice != null)
          'minPrice': filterOptions!.minPrice.toString(),
        if (filterOptions?.maxPrice != null)
          'maxPrice': filterOptions!.maxPrice.toString(),
        if (filterOptions?.location != null)
          'location': filterOptions!.location,
        if (filterOptions!.propertyTypes.isNotEmpty)
          'propertyTypes': filterOptions.propertyTypes.join(','),
        if (filterOptions.amenities.isNotEmpty)
          'amenities': filterOptions.amenities.join(','),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/search').replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'];
      } else {
        throw Exception('Failed to search');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }
}
