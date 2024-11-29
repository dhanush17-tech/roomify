import 'package:roomify_app/models/userModel.dart';

class RoommateMatch {
  final String id;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final String? university;
  final int? age;
  final String? gender;
  final String? location;
  final List<UserInterest> interests;
  final List<UserPreference> preferences;
  final double compatibilityScore;

  RoommateMatch({
    required this.id,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    this.university,
    this.age,
    this.gender,
    this.location,
    this.interests = const [],
    this.preferences = const [],
    this.compatibilityScore = 0,
  });

  factory RoommateMatch.fromJson(Map<String, dynamic> json) {
    return RoommateMatch(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bio: json['bio'] ?? '',
      university: json['university'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      location: json['location'] ?? '',
      interests: List<UserInterest>.from(
          json['interests'].map((e) => UserInterest.fromJson(e))),
      preferences: List<UserPreference>.from(
          json['preferences'].map((e) => UserPreference.fromJson(e))),
      compatibilityScore: json['compatibilityScore']?.toDouble() ?? 0,
    );
  }
}
