import 'package:roomify_app/models/itemModel.dart';

class User {
  final String id;
  String displayName;
  String? bio;
  final String email;
  String language;
  List<Listing>? favorites;
  List<Listing> listings;
  bool receiveNotifications;
  String? university;
  int? age;
  String? location;
  String? gender;
  String? profilePhotoUrl;
  double? latitude;
  double? longitude;
  final List<UserPreference> preferences;
  final List<UserSocialLink> socialLinks;
  String? status;

  User({
    required this.id,
    required this.displayName,
    this.bio,
    required this.email,
    this.language = 'English',
    this.favorites = const [],
    this.listings = const [],
    this.receiveNotifications = true,
    this.university,
    this.age,
    this.location,
    this.gender,
    this.profilePhotoUrl,
    this.latitude,
    this.longitude,
    this.preferences = const [],
    this.socialLinks = const [],
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? 'User',
      bio: json['bio'],
      email: json['email'] ?? '',
      language: json['language'] ?? 'English',
      university: json['university'],
      age: json['age'],
      location: json['location'],
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      gender: json['gender'],
      profilePhotoUrl: json['profileImageUrl'],
      favorites: json["favorites"] != null
          ? (json["favorites"] as List<dynamic>)
              .map((c) => Listing.fromJson(c["listing"]))
              .toList()
              .cast<Listing>()
          : null,
      listings: (json['listings'])
              ?.map((item) => Listing.fromJson(item))
              .toList()
              .cast<Listing>() ??
          [],
      receiveNotifications: json['receive_notifications'] == 1,
      preferences: (json['preferences'] as List<dynamic>?)
              ?.map((p) => UserPreference.fromJson(p))
              .toList() ??
          [],
      socialLinks: (json['socialLinks'] as List<dynamic>?)
              ?.map((s) => UserSocialLink.fromJson(s))
              .toList() ??
          [],
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'bio': bio,
      'email': email,
      'language': language,
      'favorites': favorites != null
          ? favorites?.map((item) => item.toJson()).toList()
          : [],
      'listings': listings.map((item) => item.toJson()).toList(),
      'receive_notifications': receiveNotifications,
      'university': university,
      'age': age,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'gender': gender,
      'profilePhoto': profilePhotoUrl,
      'status': status,
    };
  }

  User copyWith({
    String? id,
    String? displayName,
    String? bio,
    String? email,
    String? language,
    List<Listing>? favorites,
    List<Listing>? listings,
    bool? receiveNotifications,
    String? university,
    int? age,
    String? location,
    String? gender,
    String? profilePhotoUrl,
    double? latitude,
    double? longitude,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      language: language ?? this.language,
      favorites: favorites ?? this.favorites,
      listings: listings ?? this.listings,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      university: university ?? this.university,
      age: age ?? this.age,
      location: location ?? this.location,
      gender: gender ?? this.gender,
      profilePhotoUrl: profilePhotoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }

  void updateProfile({
    String? displayName,
    String? profileImageUrl,
    String? bio,
    String? university,
    int? age,
    String? location,
    String? gender,
    String? status,
  }) {
    if (displayName != null) this.displayName = displayName;
    if (bio != null) this.bio = bio;
    if (university != null) this.university = university;
    if (age != null) this.age = age;
    if (location != null) this.location = location;
    if (gender != null) this.gender = gender;
    if (profileImageUrl != null) this.profilePhotoUrl = profileImageUrl;
    if (status != null) this.status = status;
  }

  double getProfileCompletion() {
    int totalFields = 7; // Adjusted total number of required fields
    int completedFields = 0;

    if (bio != null && bio!.isNotEmpty) completedFields++;
    if (preferences.isNotEmpty) completedFields++;
    if (profilePhotoUrl != null) completedFields++;
    if (gender != null) completedFields++;
    if (status != null) completedFields++;
    if (age != null) completedFields++;
    if (socialLinks.isNotEmpty) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  bool isProfileComplete() {
    return bio != null &&
           bio!.isNotEmpty &&
           preferences.isNotEmpty &&
           profilePhotoUrl != null &&
           gender != null &&
           status != null &&
           age != null;
  }
}

class UserPreference {
  final String preference;

  UserPreference({required this.preference});

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(preference: json['preference']);
  }
}

class UserSocialLink {
  final String platform;
  final String username;

  UserSocialLink({
    required this.platform,
    required this.username,
  });

  factory UserSocialLink.fromJson(Map<String, dynamic> json) {
    return UserSocialLink(
      platform: json['platform'],
      username: json['username'],
    );
  }
}
