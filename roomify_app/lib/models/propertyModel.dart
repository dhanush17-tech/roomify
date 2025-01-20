import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';

class Property {
  final int numberOfBathrooms;
  final int numberOfBedrooms;
  final List<String> amenities;
  final bool isLookingForRoomate;
  final int maxOccupancy;
  final String? moveInDate;
  final String? moveOutDate;
  final List<PropertyCategory> categories;
  final List<String>? imageUrls;
  final double? rating;
  final bool isRoomifyChoice;

  Property({
    required this.numberOfBathrooms,
    required this.numberOfBedrooms,
    required this.amenities,
    required this.isLookingForRoomate,
    required this.maxOccupancy,
    this.moveInDate,
    this.moveOutDate,
    this.categories = const [],
    this.imageUrls,
    this.rating,
    this.isRoomifyChoice = false,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      numberOfBathrooms: json['numberOfBathrooms'] ?? 0,
      numberOfBedrooms: json['numberOfBedrooms'] ?? 0,
      amenities: List<String>.from(json['amenities'] ?? []),
      isLookingForRoomate: json['isLookingForRoomate'] ?? false,
      maxOccupancy: json['maxOccupancy'] ?? 0,
      moveInDate: json['moveInDate'] != null
          ? DateTime.parse(json['moveInDate'].length == 7
                  ? json['moveInDate'] + '-01'
                  : json['moveInDate'])
              .toLocal()
              .toString()
              .split('-')
              .sublist(0, 2)
              .join('-')
          : null,
      moveOutDate: json['moveOutDate'] != null
          ? DateTime.parse(json['moveOutDate'].length == 7
                  ? json['moveOutDate'] + '-01'
                  : json['moveOutDate'])
              .toLocal()
              .toString()
              .split('-')
              .sublist(0, 2)
              .join('-')
          : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((cat) => PropertyCategory.fromString(cat.toString()))
              .toList() ??
          [],
      imageUrls: json['images'] != null
          ? List<String>.from(json['images'].map((i) => i['imageUrl']))
          : null,
      rating: json['rating']?.toDouble(),
      isRoomifyChoice: json['isRoomifyChoice'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'numberOfBathrooms': numberOfBathrooms,
        'numberOfBedrooms': numberOfBedrooms,
        'amenities': amenities,
        'isLookingForRoomate': isLookingForRoomate,
        'maxOccupancy': maxOccupancy,
        'moveInDate': moveInDate,
        'moveOutDate': moveOutDate,
        'categories':
            categories.map((cat) => cat.toString().split('.').last).toList(),
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (rating != null) 'rating': rating,
      };
}

enum PropertyCategory {
  apartment,
  studio,
  furnished,
  house,
  villa,
  room,
  sharedHouse,
  hostel;

  static PropertyCategory fromString(String value) {
    return PropertyCategory.values.firstWhere(
      (category) => category.toString().split('.').last == value.toLowerCase(),
      orElse: () => PropertyCategory.apartment, // Default value
    );
  }

  String get displayName {
    return toString().split('.').last.toUpperCase();
  }
}

class Comment {
  final int id;
  final int propertyId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final User? user; // Optional user details that might be included

  Comment({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      propertyId: json['property_id'] as int,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'user_id': userId,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
        if (user != null) 'user': user!.toJson(),
      };
}

class PropertyLead {
  final User user;
  final String propertyTitle;
  final int viewCount;
  final DateTime lastViewed;
  final int propertyId;

  PropertyLead({
    required this.user,
    required this.propertyTitle,
    required this.viewCount,
    required this.lastViewed,
    required this.propertyId,
  });

  factory PropertyLead.fromJson(Map<String, dynamic> json) {
    return PropertyLead(
      user: User.fromJson(json['user']),
      propertyTitle: json['propertyTitle'],
      viewCount: json['viewCount'],
      lastViewed: DateTime.now(),
      //DateTime.tryParse(json['lastViewed']) ?? DateTime.now(),
      propertyId: json['propertyId'],
    );
  }
}
