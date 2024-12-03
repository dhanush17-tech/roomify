import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';

enum ListingType {
  Marketplace,
  Property;
}

class Listing {
  ListingType type;
  int id;
  String title;
  String? description; // Made optional
  DateTime createdAt;
  User? user;
  String location;
  int price;
  bool isFavourite;
  double? latitude;
  double? longitude;
  List<String> imageUrls;
  Property? property;
  MarketplaceItem? marketplaceItem;

  Listing(
      {required this.type,
      required this.id,
      required this.title,
      this.description,
      required this.createdAt,
      required this.location,
      required this.price,
      required this.isFavourite,
      required this.user,
      this.latitude = 0.0,
      this.longitude = 0.0,
      this.property,
      this.marketplaceItem,
      required this.imageUrls});

  String getListingTypeString() {
    return type.toString().split('.').last;
  }

  ListingType getListingTypeFromString(String typeString) {
    return ListingType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ListingType.Marketplace,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': getListingTypeString(), // Convert enum to string
      'id': id,
      'title': title,
      'description': description,
      'createdAt':
          createdAt.toIso8601String(), // Convert DateTime to ISO 8601 string
      'user': user?.toJson(), // Call toJson() on the User object if not null
      'location': location,
      'price': price,
      'isFavorite': isFavourite,
      if (property != null)
        'property': property?.toJson(), // Only include if not null
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
    };
  }

  static Listing fromJson(Map<String, dynamic> json) {
    return Listing(
        type: ListingType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
          orElse: () => ListingType
              .Marketplace, // Default to Marketplace if type is unknown
        ),
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'],
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
        user: json["user"] != null
            ? User.fromJson(json["user"])
            : null, // Assuming User class exists
        location: json['location'] ?? '',
        price: json['price'] ?? 0,
        isFavourite: json['isFavorite'] ?? false,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        property: json["property"] != null
            ? Property.fromJson(json["property"])
            : null,
        marketplaceItem: json["marketplace"] != null
            ? MarketplaceItem.fromJson(json["marketplace"])
            : null);
  }
}

class MarketplaceItem {
  final List<String> categories;
  final String? condition;
  final String? brand;
  final List<String> imageUrls;

  MarketplaceItem({
    required this.categories,
    this.condition,
    this.brand,
    required this.imageUrls,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      categories: json['categories']
          .map((e) => e["category"].toString())
          .cast<String>()
          .toList(),
      condition: json['condition'],
      brand: json['brand'],
      imageUrls: json["images"]
          .map((e) => e["imageUrl"].toString())
          .cast<String>()
          .toList(),
    );
  }
}
