import 'package:roomify_app/models/itemModel.dart';

class User {
  final String id;
  final String username;
  String displayName;
   String? bio;
  final String email;
  String language;
  List<Listing> favorites;
  List<Listing> listings;
  bool receiveNotifications;
  String? university;
  int? age;
  String? location;
  String? gender;
  String? profilePhotoUrl; // Added profilePhotoUrl string optional

  User({
    required this.id,
    required this.username,
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
    this.profilePhotoUrl, // Added profilePhotoUrl to the constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? 'User',
       bio: json['bio'],
      email: json['email'] ?? '',
      language: json['language'] ?? 'English',
      university: json['university'],
      age: json['age'],
      location: json['location'],
      gender: json['gender'],
      profilePhotoUrl: json['profile_image_url'], // Added profilePhotoUrl to the factory constructor
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((item) => Item.fromJson(item))
              .toList() ??
          [],
      listings: (json['listings'] as List<dynamic>?)
              ?.map((item) => Item.fromJson(item))
              .toList() ??
          [],
      receiveNotifications: json['receive_notifications'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
       'bio': bio,
      'email': email,
      'language': language,
      'favorites': favorites.map((item) => item.toJson()).toList(),
      'listings': listings.map((item) => item.toJson()).toList(),
      'receive_notifications': receiveNotifications,
      'university': university,
      'age': age,
      'location': location,
      'gender': gender,
      'profile_image_url': profilePhotoUrl, // Added profilePhotoUrl to the toJson method
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? profileImageUrl,
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
    String? profilePhotoUrl, // Added profilePhotoUrl to the copyWith method
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
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
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl, // Added profilePhotoUrl to the copyWith method
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
    String? profilePhotoUrl, // Added profilePhotoUrl to the updateProfile method
  }) {
    if (displayName != null) this.displayName = displayName;
     if (bio != null) this.bio = bio;
    if (university != null) this.university = university;
    if (age != null) this.age = age;
    if (location != null) this.location = location;
    if (gender != null) this.gender = gender;
    if (profilePhotoUrl != null) this.profilePhotoUrl = profilePhotoUrl; // Added profilePhotoUrl to the updateProfile method
  }
}
