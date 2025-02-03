import 'dart:convert';

import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';

class Property {
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final int maxOccupancy;
  String moveInDate;
  String? moveOutDate;
  final bool isLookingForRoomate;
  final double? rating;
  final List<String> amenities;
  final List<String> categories;
  final List<String> imageUrls;
  final int? walkScore;
  final int? transitScore;
  final Map<String, dynamic> transitDetails;
  final DateTime? lastLocationDetailsUpdate;
  final bool isRoomifyChoice;
  final List<FloorPlan>? floorPlans;
  final bool isProfessionalListing;

  Property({
    this.transitScore = 0,
    this.walkScore = 0,
    this.transitDetails = const {'railLines': [], 'busLines': []},
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.maxOccupancy,
    required this.moveInDate,
    this.moveOutDate,
    required this.isLookingForRoomate,
    this.rating,
    required this.amenities,
    required this.categories,
    required this.imageUrls,
    this.lastLocationDetailsUpdate,
    this.isRoomifyChoice = false,
    this.floorPlans = const [],
    this.isProfessionalListing = false,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      numberOfBedrooms: json['numberOfBedrooms'] ?? 0,
      numberOfBathrooms: json['numberOfBathrooms'] ?? 0,
      maxOccupancy: json['maxOccupancy'] ?? 0,
      moveInDate: json['moveInDate'] ?? '',
      moveOutDate: json['moveOutDate'],
      isLookingForRoomate: json['isLookingForRoomate'] ?? false,
      rating: json['rating']?.toDouble(),
      amenities:
          List<String>.from(json['amenities']?.map((x) => x['amenity']) ?? []),
      categories: [],
      //List<String>.from(
      // json['categories']?.map((x) => x['category']) ?? []),
      imageUrls:
          List<String>.from(json['images']?.map((x) => x['imageUrl']) ?? []),
      walkScore: json['walkScore'],
      transitScore: json['transitScore'],
      transitDetails: json['transitDetails'] != null
          ? jsonDecode(json['transitDetails'])
          : {'railLines': [], 'busLines': []},
      lastLocationDetailsUpdate: json['lastLocationDetailsUpdate'] != null
          ? DateTime.parse(json['lastLocationDetailsUpdate'])
          : null,
      isRoomifyChoice: json['isRoomifyChoice'] ?? false,
      floorPlans: json['floorPlans'] != null
          ? List<FloorPlan>.from(
              json['floorPlans'].map((x) => FloorPlan.fromJson(x)))
          : [],
      isProfessionalListing: json['isProfessionalListing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfBedrooms': numberOfBedrooms,
      'numberOfBathrooms': numberOfBathrooms,
      'maxOccupancy': maxOccupancy,
      'moveInDate': moveInDate,
      'moveOutDate': moveOutDate,
      'isLookingForRoomate': isLookingForRoomate,
      'rating': rating,
      'amenities': amenities,
      'categories': categories,
      'imageUrls': imageUrls,
      'walkScore': walkScore,
      'transitScore': transitScore,
      'transitDetails': transitDetails,
      'lastLocationDetailsUpdate': lastLocationDetailsUpdate?.toIso8601String(),
      'isRoomifyChoice': isRoomifyChoice,
      'floorPlans': floorPlans?.map((plan) => plan.toJson()).toList() ?? [],
      'isProfessionalListing': isProfessionalListing,
    };
  }

  Property copyWith({
    int? id,
    String? title,
    String? description,
    String? location,
    double? price,
    int? numberOfBedrooms,
    int? numberOfBathrooms,
    int? maxOccupancy,
    String? moveInDate,
    String? moveOutDate,
    int? walkScore,
    int? transitScore,
    Map<String, dynamic>? transitDetails,
    DateTime? lastLocationUpdate,
    bool? isRoomifyChoice,
    List<String>? imageUrls,
    List<String>? categories,
    List<String>? amenities,
    List<String>? tags,
    List<FloorPlan>? floorPlans,
    bool? isLookingForRoomate,
    bool? isProfessionalListing,
  }) {
    return Property(
      numberOfBedrooms: numberOfBedrooms ?? this.numberOfBedrooms,
      numberOfBathrooms: numberOfBathrooms ?? this.numberOfBathrooms,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      moveInDate: moveInDate ?? this.moveInDate,
      moveOutDate: moveOutDate ?? this.moveOutDate,
      walkScore: walkScore ?? this.walkScore,
      transitScore: transitScore ?? this.transitScore,
      transitDetails: transitDetails ?? this.transitDetails,
      lastLocationDetailsUpdate:
          lastLocationUpdate ?? this.lastLocationDetailsUpdate,
      isRoomifyChoice: isRoomifyChoice ?? this.isRoomifyChoice,
      imageUrls: imageUrls ?? List<String>.from(this.imageUrls),
      categories: categories ?? List<String>.from(this.categories),
      amenities: amenities ?? List<String>.from(this.amenities),
      floorPlans: floorPlans ?? List<FloorPlan>.from(this.floorPlans ?? []),
      isLookingForRoomate: isLookingForRoomate ?? this.isLookingForRoomate,
      isProfessionalListing:
          isProfessionalListing ?? this.isProfessionalListing,
    );
  }
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

class FloorPlan {
  final String id;
  final String name;
  String imageUrl;
  final int bedrooms;
  final int bathrooms;
  final double price;
  final double squareFeet;
  final int availableUnits;

  FloorPlan({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.bedrooms,
    required this.bathrooms,
    required this.price,
    required this.squareFeet,
    required this.availableUnits,
  });

  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    return FloorPlan(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      price: json['price'].toDouble(),
      squareFeet: json['squareFootage'].toDouble() ?? 0,
      availableUnits: json['unitsAvailable'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'price': price,
      'squareFootage': squareFeet,
      'unitsAvailable': availableUnits,
    };
  }
}

class TransitDetails {
  final int walkScore;
  final int transitScore;
  final List<TransitRoute> railLines;
  final List<TransitRoute> busLines;

  TransitDetails({
    required this.walkScore,
    required this.transitScore,
    required this.railLines,
    required this.busLines,
  });

  factory TransitDetails.fromJson(Map<String, dynamic> json) {
    return TransitDetails(
      walkScore: json['walkScore'] ?? 0,
      transitScore: json['transitScore'] ?? 0,
      railLines: (json['transitDetails']?['railLines'] as List<dynamic>?)
              ?.map((route) => TransitRoute.fromJson(route))
              .toList() ??
          [],
      busLines: (json['transitDetails']?['busLines'] as List<dynamic>?)
              ?.map((route) => TransitRoute.fromJson(route))
              .toList() ??
          [],
    );
  }
}

class TransitRoute {
  final String name;
  final double distance;
  final String description;
  final String agency;
  final String type;

  TransitRoute({
    required this.name,
    required this.distance,
    required this.description,
    required this.agency,
    required this.type,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) {
    return TransitRoute(
      name: json['name'] ?? 'Unknown Route',
      distance: (json['distance'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      agency: json['agency'] ?? 'Unknown Agency',
      type: json['type'] ?? 'Unknown',
    );
  }
}
