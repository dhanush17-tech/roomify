import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils.dart';

class RoommateMatchRepository {
  RoommateMatchRepository();

  Future<List<User>> getMutualMatches() async {
    try {
      final token = await AuthRepository().getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/roommate-match/matches'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['matches'];
        return data.map((json) => User.fromJson(json['user'])).toList();
      } else {
        throw Exception('Failed to load mutual matches');
      }
    } catch (e) {
      throw Exception('Failed to load mutual matches: $e');
    }
  }

  Future<List<User>> getMatches() async {
    try {
      final token = await AuthRepository().getToken();
      final response =
          await http.get(Uri.parse('$baseUrl/api/roommate-match'), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['matches'];
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load matches');
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<User?> recordSwipe(String userId, String direction) async {
    try {
      final token = await AuthRepository().getToken();
      final response =
          await http.post(Uri.parse('$baseUrl/api/roommate-match/swipe'),
              headers: {
                'Authorization': 'Bearer $token',
              },
              body: json.encode({'userId': userId, 'direction': direction}));
      final data = jsonDecode(response.body);
      return data['matched'] ? User.fromJson(data['matchedUser']) : null;
    } catch (e) {
      throw Exception('Failed to record swipe');
    }
  }
}
