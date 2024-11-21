import 'dart:io';

import 'package:dio/dio.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';

class PropertyRepository {
   final Dio _dio;

  PropertyRepository() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthRepository().getToken();
          options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
      ),
    );
  }

  Future<String> createProperty(Property property, List<File> images) async {
    try {
      final formData = FormData.fromMap({
        ...property.toJson(),
        'images': images
            .map((image) => MultipartFile.fromFileSync(
                  image.path,
                  filename: image.path.split('/').last,
                ))
            .toList(),
      });

      final response = await _dio.post(
        '/api/properties',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['propertyId'];
      } else {
        throw Exception('Failed to create property');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
