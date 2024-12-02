import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';

class Property {
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final int maxOccupancy;
  final bool isLookingForRoomate;
  final double? rating;
  final List<String> amenities;
  final List<String>? tags;
  final List<Comment>? comments;
  List<String>? imageUrls;
  final String? moveInDate;
  final String? moveOutDate;

  Property({
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.maxOccupancy,
    required this.isLookingForRoomate,
    this.rating,
    required this.amenities,
    this.tags,
    this.imageUrls,
    this.comments,
    this.moveInDate,
    this.moveOutDate,
  });
  Map<String, dynamic> toJson() {
    return {
      'numberOfBedrooms': numberOfBedrooms,
      'numberOfBathrooms': numberOfBathrooms,
      'maxOccupancy': maxOccupancy,
      'isLookingForRoomate': isLookingForRoomate,
      'rating': rating,
      'amenities': amenities,
      'tags': tags,
      'moveInDate': moveInDate,
      'moveOutDate': moveOutDate,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      numberOfBedrooms: json['numberOfBedrooms'] ?? 0,
      numberOfBathrooms: json['numberOfBathrooms'] ?? 0,
      maxOccupancy: json['maxOccupancy'] ?? 0,
      isLookingForRoomate: json['isLookingForRoomate'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      amenities: List<String>.from(json["amenities"] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      comments: json['comments'] != null
          ? List<Comment>.from(json['comments'].map((x) => Comment.fromJson(x)))
          : null,
      moveInDate: json['moveInDate'],
      moveOutDate: json['moveOutDate'],
    );
  }
}

enum PropertyCategory {
  Apartment,
  Studio,
  SharedHouse,
  PrivateResidence,
  RoomForRent,
  Hostel,
  StudentHousing,
  Condo,
  Townhouse,
  Duplex
}

extension PropertyCategoryExtension on PropertyCategory {
  String get displayName {
    return this
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
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
