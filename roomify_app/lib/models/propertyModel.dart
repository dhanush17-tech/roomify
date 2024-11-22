import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';

class Property extends Listing {
  final String title;
  final String description;
  final String location;
  final int price;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final int maxOccupancy;
  final List<String> amenities;
  final List<String> categories;
  final List<String> imageUrls;
  final DateTime createdAt;
  final List<Comment>? comments;
  final int? rating;
  final bool? isLookingForRoomate;

  Property({
    required this.createdAt,
    int? id,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.maxOccupancy,
    ListingType? type,
    required this.amenities,
    required this.categories,
    User? user,
    double? latitude,
    double? longitude,
    bool? isFavourite,
    this.imageUrls = const [],
    this.comments = const [],
    this.rating = 0,
    this.isLookingForRoomate = false,
  }) : super(
            type: ListingType.Property,
            id: id = 1,
            location: location,
            price: price,
            user: user,
            title: title,
            description: description,
            createdAt: createdAt ?? DateTime.now(), // Default to current time
            isFavourite: isFavourite ?? false, // Default to false
            latitude: latitude,
            longitude: longitude);
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'price': price,
        'numberOfBedrooms': numberOfBedrooms,
        'numberOfBathrooms': numberOfBathrooms,
        'maxOccupancy': maxOccupancy,
        'type': type.toString().split('.').last,
        'amenities': amenities,
        'categories': categories,
        'user': user,
      };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        location: json['location'],
        price: json['price'],
        numberOfBedrooms: json['numberOfBedrooms'] ?? 0,
        numberOfBathrooms: json['numberOfBathrooms'] ?? 0,
        maxOccupancy: json['maxOccupancy']??0,
        type: ListingType.Property,
        user: User.fromJson(json["user"]),
        amenities: List<String>.from(json['amenities'] ?? []),
        categories: List<String>.from(json['categories'] ?? []),
        imageUrls: List<String>.from(json['images'] ?? []),
        rating: json["rating"]??0,
        longitude: json["longitude"],
        latitude: json["latitude"],
        isLookingForRoomate: json["isLookingForRoomate"],
        comments: List<Comment>.from(json["comments"] ?? []),
        createdAt: DateTime.parse(json["createdAt"]));
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
