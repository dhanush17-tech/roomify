class RoommateMatch {
  final String id;
   final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final String? university;
  final int? age;
  final String? gender;
  final String? location;
  final List<String> interests;
  final List<String> preferences;
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
      profileImageUrl: json['profile_image_url'] ?? '',
      bio: json['bio'] ?? '',
      university: json['university'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      location: json['location'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      preferences: List<String>.from(json['preferences'] ?? []),
      compatibilityScore: json['compatibility_score']?.toDouble() ?? 0,
    );
  }
}
