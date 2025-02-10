import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String? token;

  ApiService({required this.baseUrl, this.token});

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }

  Future<http.Response> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    return await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
